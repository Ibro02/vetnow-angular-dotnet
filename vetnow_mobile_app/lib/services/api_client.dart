import 'dart:convert';
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

/// Thin wrapper around package:http — attaches the auth header when a
/// token is provided, decodes JSON, and turns non-2xx responses into
/// ApiException with the backend's own error message when possible.
class ApiClient {
  ApiClient._();

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

  static Future<dynamic> get(String path, {Map<String, dynamic>? query, String? token}) async {
    final res = await http.get(_uri(path, query), headers: _headers(token));
    return _decode(res);
  }

  static Future<dynamic> post(String path, {Object? body, String? token}) async {
    final res = await http.post(_uri(path), headers: _headers(token), body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  static Future<dynamic> put(String path, {Object? body, String? token}) async {
    final res = await http.put(_uri(path), headers: _headers(token), body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  static Future<dynamic> delete(String path, {Map<String, dynamic>? query, String? token}) async {
    final res = await http.delete(_uri(path, query), headers: _headers(token));
    return _decode(res);
  }
}
