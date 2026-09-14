// Smoke tests for the VetNow app shell.
//
// The original version of this file was the untouched Flutter template —
// it referenced a `MyApp` widget that does not exist here, so it failed to
// compile and `flutter analyze` reported a hard error.
//
// These tests boot the real root widget. No server and no platform
// plugins are available in a widget test, which is deliberate: it proves
// the app degrades to the guest shell instead of hanging or crashing when
// secure storage and the backend are both unreachable.

import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/main.dart';
import 'package:vetnow_mobile/state/auth_state.dart';
import 'package:vetnow_mobile/widgets/luxury_nav_bar.dart';

void main() {
  /// Boots the app and waits for session restore to finish.
  ///
  /// Restore crosses a platform channel (secure storage), which does not
  /// advance on the test's fake clock — `runAsync` gives it real time.
  /// `pumpAndSettle` is deliberately avoided: Explore fires a request at
  /// a backend that isn't running here, so there is never a fully idle
  /// frame to settle on.
  Future<void> bootApp(WidgetTester tester) async {
    await tester.pumpWidget(const VetNowApp());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }

  AuthState authOf(WidgetTester tester) {
    final state = tester.state(find.byType(VetNowApp)) as dynamic;
    return state.debugAuthState as AuthState;
  }

  testWidgets('boots into the guest shell once session restore settles', (WidgetTester tester) async {
    await bootApp(tester);
    expect(find.byType(LuxuryNavBar), findsOneWidget);
  });

  testWidgets('session restore never leaves the app stuck on the splash', (WidgetTester tester) async {
    await bootApp(tester);

    // Guards the failure mode that would be worst in production: an
    // unreadable or unreachable session leaving `isRestoring` true
    // forever, so the person only ever sees the loading screen.
    final auth = authOf(tester);
    expect(auth.isRestoring, isFalse);
    expect(auth.isLoggedIn, isFalse, reason: 'no stored token in a fresh test environment');
  });
}
