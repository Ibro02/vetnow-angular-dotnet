// What happens when the backend stops accepting the token.
//
// Not a hypothetical: a saved session is restored at every launch, and
// tokens do not last forever. Before this, an expired one meant every
// screen behind the login showed "Request failed (401)." above a retry
// button that could only ever fail the same way, with no route back to
// the sign-in screen short of reinstalling the app.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/my_appointments_screen.dart';
import 'package:vetnow_mobile/services/api_client.dart';
import 'package:vetnow_mobile/state/auth_state.dart';
import 'package:vetnow_mobile/widgets/auth_prompt.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    resetBackend();
    ApiClient.onSessionExpired = null;
  });

  group('AuthState.expire', () {
    test('clears the session and says why', () {
      final auth = AuthState()
        ..isLoggedIn = true
        ..isRestoring = false
        ..token = 'stale'
        ..userId = 42
        ..displayName = 'Test Korisnik';

      auth.expire();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.token, isNull);
      expect(auth.userId, isNull);
      expect(auth.sessionExpired, isTrue);
    });

    test('is a no-op for someone who was never signed in', () {
      // Otherwise a guest browsing Explore, where several endpoints are
      // anonymous, could be "signed out" of nothing and shown a notice
      // about a session they never had.
      final auth = AuthState()..isRestoring = false;

      auth.expire();

      expect(auth.sessionExpired, isFalse);
    });

    test('signing back in clears the notice', () async {
      useBackend(FakeBackend({
        'LoginAuth': (_) => {'token': 'fresh'},
        'ProfileSettings': (_) => {'id': 42, 'firstName': 'Test'},
      }));

      final auth = AuthState()
        ..isLoggedIn = true
        ..isRestoring = false
        ..token = 'stale';
      auth.expire();
      expect(auth.sessionExpired, isTrue);

      await auth.loginWithToken('fresh', fallbackName: 'test@vetnow.ba');

      expect(auth.sessionExpired, isFalse);
      expect(auth.isLoggedIn, isTrue);
    });
  });

  group('ApiClient', () {
    test('a 401 on an authenticated request expires the session', () async {
      useBackend(FakeBackend({})..unauthorized.add('/'));

      var expired = false;
      ApiClient.onSessionExpired = () => expired = true;

      await expectLater(
        ApiClient.get('/api/Animal/GetByOwnerId', token: 'stale'),
        throwsA(isA<ApiException>()),
      );

      expect(expired, isTrue);
    });

    test('a 401 without a token does not, because that is a bad password',
        () async {
      // The login endpoint answers 401 for wrong credentials and again
      // for an account that still needs verifying. Neither is an expired
      // session, and signing somebody out mid-sign-in would be absurd.
      useBackend(FakeBackend({})..unauthorized.add('/'));

      var expired = false;
      ApiClient.onSessionExpired = () => expired = true;

      await expectLater(
        ApiClient.post('/api/LoginAuth/Post', body: {'username': 'x'}),
        throwsA(isA<ApiException>()),
      );

      expect(expired, isFalse);
    });
  });

  testWidgets('the sign-in prompt says the session ran out', (tester) async {
    useBackend(FakeBackend({}));

    final auth = AuthState()
      ..isLoggedIn = true
      ..isRestoring = false
      ..token = 'stale';
    auth.expire();

    await usePhoneScreen(tester);
    await tester.pumpWidget(
      harness(const MyAppointmentsScreen(), signedIn: false, auth: auth),
    );
    // Fixed frames: the prompt sits on the animated hero backdrop,
    // which never stops drifting, so there is nothing to settle into.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(AuthPrompt), findsOneWidget);
    expect(find.textContaining('Sesija'), findsOneWidget);
  });

  testWidgets('a plain guest sees no such notice', (tester) async {
    useBackend(FakeBackend({}));

    await usePhoneScreen(tester);
    await tester.pumpWidget(
      harness(const MyAppointmentsScreen(), signedIn: false),
    );
    // Fixed frames: the prompt sits on the animated hero backdrop,
    // which never stops drifting, so there is nothing to settle into.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(AuthPrompt), findsOneWidget);
    expect(find.textContaining('Sesija'), findsNothing);
  });
}

