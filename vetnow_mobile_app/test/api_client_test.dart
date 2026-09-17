// The HTTP layer's failure behaviour.
//
// The rule worth protecting here is the asymmetry: a read that dropped
// can be asked again, a write cannot. Retrying a POST that actually
// succeeded books the same appointment twice, and nobody finds out until
// two people show up for one slot.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:vetnow_mobile/services/api_client.dart';

/// Answers from a script, and counts what it was asked.
class _ScriptedClient extends http.BaseClient {
  final List<FutureOr<http.Response> Function()> script;
  final List<http.BaseRequest> calls = [];

  _ScriptedClient(this.script);

  /// Every call answers the same way.
  _ScriptedClient.always(FutureOr<http.Response> Function() answer)
      : script = [],
        _always = answer;

  FutureOr<http.Response> Function()? _always;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls.add(request);
    final answer = _always ?? script[calls.length - 1];
    final res = await answer();
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      request: request,
      headers: res.headers,
    );
  }
}

http.Response _ok([String body = '{"ok":true}']) => http.Response(body, 200);

void main() {
  tearDown(() => ApiClient.client = http.Client());

  group('reads', () {
    test('a dropped connection is retried, and the retry is returned',
        () async {
      var attempts = 0;
      ApiClient.client = _ScriptedClient.always(() {
        attempts++;
        if (attempts < 3) throw const SocketException('no route to host');
        return _ok('{"value":42}');
      });

      final result = await ApiClient.get('/api/thing');

      expect(attempts, 3);
      expect(result, {'value': 42});
    });

    test('it gives up rather than hammering a server that is really down',
        () async {
      var attempts = 0;
      ApiClient.client = _ScriptedClient.always(() {
        attempts++;
        throw const SocketException('down');
      });

      await expectLater(
        ApiClient.get('/api/thing'),
        throwsA(isA<NetworkException>()),
      );
      // The first try plus the two backoffs, and no more.
      expect(attempts, 3);
    });

    test('a server that is briefly unavailable is retried', () async {
      var attempts = 0;
      ApiClient.client = _ScriptedClient.always(() {
        attempts++;
        return attempts < 2 ? http.Response('busy', 503) : _ok();
      });

      await ApiClient.get('/api/thing');
      expect(attempts, 2);
    });

    test('a refusal is an answer, not a blip — it is not retried', () async {
      var attempts = 0;
      ApiClient.client = _ScriptedClient.always(() {
        attempts++;
        return http.Response('"Nema takve klinike."', 404);
      });

      await expectLater(
        ApiClient.get('/api/thing'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Nema takve klinike.')),
      );
      expect(attempts, 1);
    });
  });

  group('writes', () {
    test('a booking that timed out is never sent twice', () async {
      var attempts = 0;
      ApiClient.client = _ScriptedClient.always(() {
        attempts++;
        throw const SocketException('dropped');
      });

      await expectLater(
        ApiClient.post('/api/Appointment/Add', body: {'slot': 1}),
        throwsA(isA<NetworkException>()),
      );
      expect(attempts, 1);
    });

    test('neither is a cancellation or a reschedule', () async {
      for (final send in [
        () => ApiClient.put('/api/Appointment/Reschedule', body: {}),
        () => ApiClient.delete('/api/LoginAuth/Delete'),
      ]) {
        var attempts = 0;
        ApiClient.client = _ScriptedClient.always(() {
          attempts++;
          throw const SocketException('dropped');
        });

        await expectLater(send(), throwsA(isA<NetworkException>()));
        expect(attempts, 1);
      }
    });
  });

  group('hanging server', () {
    test('a request that is never answered fails instead of waiting forever',
        () {
      // A server that accepted the connection and then went quiet. Without
      // a timeout the screen sits on skeletons with no error and no retry.
      ApiClient.client = _ScriptedClient.always(
        () => Future<http.Response>.delayed(const Duration(minutes: 5), _ok),
      );

      fakeAsync((async) {
        Object? thrown;
        unawaited(ApiClient.get('/api/thing').then<void>(
          (_) {},
          onError: (Object e) => thrown = e,
        ));

        // Just short of the budget nothing has failed yet...
        async.elapse(ApiClient.timeout - const Duration(seconds: 1));
        expect(thrown, isNull);

        // ...and just past it the caller is told, rather than waiting out
        // the five minutes the server is going to take. The budget covers
        // the retries too, so this is the whole call, not one attempt.
        async.elapse(const Duration(seconds: 2));
        expect(thrown, isA<NetworkException>());
      });
    });
  });

  group('auth header', () {
    test('travels on every verb, and only when there is a token', () async {
      final client = _ScriptedClient.always(_ok);
      ApiClient.client = client;

      await ApiClient.get('/a', token: 'tok');
      await ApiClient.post('/b');

      expect(client.calls[0].headers['my-auth-token'], 'tok');
      expect(client.calls[1].headers.containsKey('my-auth-token'), isFalse);
    });

    test('null query values are dropped rather than sent as "null"',
        () async {
      final client = _ScriptedClient.always(_ok);
      ApiClient.client = client;

      await ApiClient.get('/a', query: {'city': null, 'page': 1});

      expect(client.calls.single.url.queryParameters, {'page': '1'});
    });
  });
}
