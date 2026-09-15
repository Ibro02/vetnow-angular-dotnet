import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Thrown for any non-2xx response. Carries the backend's message when
/// the body is plain text or a JSON object with a recognizable field —
/// FastEndpoints in this backend often return BadRequest("some string")
/// or NotFound("some string"), so the body is frequently plain text.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Decoded error body, when it was JSON. Some endpoints answer with a
  /// structured payload rather than a sentence — the login endpoint, for
  /// one, returns `{userId, needsVerification}` on 401, and the caller
  /// needs that id to continue into the verification flow. Null when the
  /// body was plain text or empty.
  final dynamic body;

  ApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => message;
}

/// The request never reached a server, or the server never answered.
///
/// Deliberately not an [ApiException]: "we could not ask" and "the server
/// said no" are different things to a person, and the screens already
/// render them differently. Screens catch this through their generic
/// `catch` and fall back to the 'network' sentinel, so this type exists
/// mainly so the retry logic and the crash log can tell the two apart.
class NetworkException implements Exception {
  final Object cause;

  NetworkException(this.cause);

  @override
  String toString() => 'network';
}

/// Thin wrapper around package:http — attaches the auth header when a
/// token is provided, decodes JSON, and turns non-2xx responses into
/// ApiException with the backend's own error message when possible.
///
/// Three things it does that the bare `http` top-level functions do not:
///
///  * **One pooled client.** `http.get` opens a fresh connection per call
///    and closes it after. Explore alone fires several requests on open;
///    reusing the connection saves a TCP and TLS handshake on each one,
///    which is the difference between a list that appears and a list that
///    arrives.
///  * **A timeout.** Without one a half-open socket — a phone that lost
///    signal mid-request, a server that accepted and then hung — leaves
///    the screen on skeletons forever, with no error and no retry.
///  * **Retries, but only where they are safe.** A dropped GET can be
///    asked again. A POST cannot: retrying an appointment that in fact
///    succeeded books the same slot twice, and the person finds out at
///    the clinic. So reads retry and writes fail fast.
class ApiClient {
  ApiClient._();

  /// How long a call may take in total — every attempt and every backoff
  /// together, not per attempt.
  ///
  /// Per-attempt would multiply: three tries at twenty seconds each is a
  /// minute of skeletons before anyone is told anything, which is well
  /// past the point where people decide the app is broken and close it.
  /// One budget means a failure is reported when it is still worth
  /// reporting.
  static const Duration timeout = Duration(seconds: 20);

  /// Two retries, backing off. Past that it is not a blip and saying so
  /// is more useful than trying a fourth time.
  static const List<Duration> _backoff = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 1200),
  ];

  static http.Client _client = http.Client();

  /// Swapped by tests for a mock. Closes whatever was in use first, so a
  /// test never leaves a live connection behind.
  @visibleForTesting
  static set client(http.Client value) {
    _client.close();
    _client = value;
  }

  @visibleForTesting
  static http.Client get client => _client;

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? cleanQuery;
    if (query != null) {
      cleanQuery = {};
      query.forEach((k, v) {
        if (v != null) cleanQuery![k] = v.toString();
      });
    }
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: (cleanQuery == null || cleanQuery.isEmpty) ? null : cleanQuery,
    );
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) ApiConfig.authHeaderName: token,
      };

  /// True for failures that are worth asking again about: the request
  /// never landed, or it landed on a server that is momentarily unable to
  /// answer. A 404 or a 400 is an answer and retrying it changes nothing.
  static bool _isTransient(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException ||
      (error is ApiException &&
          (error.statusCode == 502 || error.statusCode == 503 || error.statusCode == 504));

  /// Runs [send], retrying transient failures when [retry] is set.
  static Future<dynamic> _run(
    Future<http.Response> Function() send, {
    required bool retry,
  }) async {
    // clock.now() rather than DateTime.now(): the deadline is testable
    // this way, so the timeout has a test that does not take twenty
    // seconds to run.
    final started = clock.now();
    Duration remaining() => timeout - clock.now().difference(started);

    var attempt = 0;
    while (true) {
      final budget = remaining();
      if (budget <= Duration.zero) {
        throw NetworkException(TimeoutException('No time left', timeout));
      }

      try {
        return _decode(await send().timeout(budget));
      } catch (error) {
        final canRetry = retry && _isTransient(error) && attempt < _backoff.length;

        // Only worth backing off if there is enough of the budget left to
        // wait *and* then ask again. Otherwise fail now and let the screen
        // offer a retry button, which puts the choice with the person
        // rather than spending their last second on a doomed attempt.
        if (canRetry && remaining() > _backoff[attempt]) {
          await Future<void>.delayed(_backoff[attempt]);
          attempt++;
          continue;
        }

        // An ApiException is the server's own answer and travels as-is;
        // anything else means we never got one.
        if (error is ApiException) rethrow;
        throw NetworkException(error);
      }
    }
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }
    // Try to pull a readable message out of the error body — the
    // backend usually returns either plain text or {"message": "..."}.
    String message = 'Request failed (${res.statusCode}).';
    dynamic decodedBody;

    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        decodedBody = decoded;
        if (decoded is String) {
          message = decoded;
        } else if (decoded is Map && decoded['message'] is String) {
          message = decoded['message'];
        } else if (decoded is Map && decoded['title'] is String) {
          message = decoded['title'];
        }
      } catch (_) {
        message = res.body;
      }
    }
    throw ApiException(res.statusCode, message, body: decodedBody);
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query, String? token}) {
    return _run(
      () => _client.get(_uri(path, query), headers: _headers(token)),
      retry: true,
    );
  }

  static Future<dynamic> post(String path, {Object? body, String? token}) {
    return _run(
      () => _client.post(
        _uri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      ),
      // Never retried: a booking that timed out may well have been
      // recorded, and asking again would make a second one.
      retry: false,
    );
  }

  static Future<dynamic> put(String path, {Object? body, String? token}) {
    return _run(
      () => _client.put(
        _uri(path),
        headers: _headers(token),
        body: body == null ? null : jsonEncode(body),
      ),
      retry: false,
    );
  }

  static Future<dynamic> delete(String path, {Map<String, dynamic>? query, String? token}) {
    return _run(
      () => _client.delete(_uri(path, query), headers: _headers(token)),
      retry: false,
    );
  }
}
