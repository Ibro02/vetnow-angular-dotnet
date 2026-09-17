// The three cards shown the first time the app is opened.
//
// The app used to open straight onto Explore with no word about what it
// is, so somebody who installed it on a recommendation arrived at a list
// of clinics and worked the rest out from the icons — and the one thing
// that actually distinguishes VetNow, that you can browse and book with
// no account, was the least visible thing on screen.
//
// Note that widget_test.dart does not cover any of this and cannot: it
// leaves SharedPreferences unmocked, so FirstRun falls through to its
// "already seen" default and the shell appears. That default is correct
// — an introduction shown on every launch because storage is
// unavailable would be the most irritating bug in the app — but it means
// the flow needs its own file, with the plugin actually mocked.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/main.dart';
import 'package:vetnow_mobile/screens/onboarding_screen.dart';
import 'package:vetnow_mobile/services/first_run.dart';
import 'package:vetnow_mobile/widgets/luxury_nav_bar.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetBackend);

  /// Boots the app and lets the session restore and the first-run check
  /// both finish.
  ///
  /// Both cross a platform channel, which does not advance on the test's
  /// fake clock, so they need real time. pumpAndSettle is avoided
  /// throughout: Explore fires a request at a backend that is not
  /// running, so there is never a fully idle frame.
  Future<void> boot(WidgetTester tester) async {
    useBackend(FakeBackend({'VetStationSearch': (_) => stations()}));
    await tester.pumpWidget(const VetNowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('a fresh install gets the introduction', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await boot(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Pronađi kliniku'), findsOneWidget);
    // And not the app behind it: covering the shell a frame after
    // showing it would be worse than waiting.
    expect(find.byType(LuxuryNavBar), findsNothing);
  });

  testWidgets('skip goes straight to the app', (tester) async {
    // On screen from the first frame on purpose. This is an offer, not a
    // toll gate.
    SharedPreferences.setMockInitialValues({});
    await boot(tester);

    await tester.tap(find.text('Preskoči'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LuxuryNavBar), findsOneWidget);
  });

  testWidgets('walking through all three ends on the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await boot(tester);

    expect(find.text('Dalje'), findsOneWidget);

    await tester.tap(find.text('Dalje'));
    // Fixed frames: the ink background drifts continuously, so there is
    // no settled frame to wait for.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('Rezerviši za par klikova'), findsOneWidget);

    await tester.tap(find.text('Dalje'));
    // Fixed frames: the ink background drifts continuously, so there is
    // no settled frame to wait for.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('Sve o tvom ljubimcu'), findsOneWidget);

    // The last card offers to start rather than to continue.
    expect(find.text('Dalje'), findsNothing);
    await tester.tap(find.text('Počni'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(LuxuryNavBar), findsOneWidget);
  });

  testWidgets('it is not shown a second time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await boot(tester);
    await tester.tap(find.text('Preskoči'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // Same stored preferences, fresh app.
    await tester.pumpWidget(const VetNowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LuxuryNavBar), findsOneWidget);
  });

  group('FirstRun', () {
    test('a fresh device owes the introduction', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await FirstRun.shouldShowOnboarding(), isTrue);
    });

    test('and stops owing it once it has been seen', () async {
      SharedPreferences.setMockInitialValues({});
      await FirstRun.markSeen();
      expect(await FirstRun.shouldShowOnboarding(), isFalse);
    });

    test('reset puts it back, for anyone testing the flow', () async {
      SharedPreferences.setMockInitialValues({'vetnow.onboarding.seen': true});
      await FirstRun.reset();
      expect(await FirstRun.shouldShowOnboarding(), isTrue);
    });
  });
}
