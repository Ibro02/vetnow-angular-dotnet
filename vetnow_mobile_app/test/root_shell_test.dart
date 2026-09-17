// The app shell: which tab you are on, and what happens on the way in.
//
// Both groups here come from driving the app on a phone rather than from
// reading it. Tapping into the search field threw for a single frame —
// long enough to paint Flutter's red error screen and no longer, so it
// registered as "something flashed" and nothing more. And signing in
// left you on whichever tab you had started from, which after a sign-in
// prompt is the one screen you were not trying to reach.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/root_shell.dart';
import 'package:vetnow_mobile/state/auth_state.dart';

import 'support/fake_backend.dart';

/// Fixed frames rather than pumpAndSettle: Explore's hero drifts
/// continuously and the placeholders shimmer on a loop, so there is no
/// quiet frame to settle into and pumpAndSettle just times out.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(resetBackend);

  FakeBackend healthy() => FakeBackend({
        'VetStationSearch': (_) => stations(),
        'VetStation/GetAll': (_) => stations(),
        'Review/GetByVetStation': (_) =>
            {'average': 4.4, 'count': 5, 'reviews': <Map<String, dynamic>>[]},
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
        'ProfileSettings': (_) => <String, dynamic>{},
      });

  late FakeBackend backend;

  Future<void> openShell(WidgetTester tester, {AuthState? auth}) async {
    backend = healthy();
    useBackend(backend);
    await usePhoneScreen(tester);
    await tester.pumpWidget(
      harness(const RootShell(), signedIn: auth == null, auth: auth),
    );
    await settle(tester);
  }

  group('the search field', () {
    testWidgets('can be tapped without throwing', (tester) async {
      await openShell(tester);

      await tester.tap(find.byType(TextField));
      await settle(tester, frames: 4);

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives the keyboard taking half the screen', (tester) async {
      // The other half of the same gesture: focus opens the keyboard,
      // which cuts the viewport roughly in half in a single frame.
      await openShell(tester);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      tester.view.viewInsets = const FakeViewPadding(bottom: 1200);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester, frames: 4);

      expect(tester.takeException(), isNull);
    });

    testWidgets('filters the list as you type', (tester) async {
      await openShell(tester);

      expect(find.textContaining('Happy Paws'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Mostar');
      await settle(tester, frames: 4);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Happy Paws'), findsNothing);
      expect(find.textContaining('PetCare'), findsWidgets);
    });

    testWidgets('offers a way to clear itself, but only once it has text',
        (tester) async {
      await openShell(tester);

      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'Mostar');
      await settle(tester, frames: 4);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await settle(tester, frames: 4);

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.textContaining('Happy Paws'), findsWidgets);
    });
  });

  group('signing in', () {
    testWidgets('lands on Explore, whichever tab it was started from',
        (tester) async {
      final auth = AuthState()..isRestoring = false;
      await openShell(tester, auth: auth);

      // Wander off first, the way someone does before they reach a
      // screen that asks them to sign in.
      await tester.tap(find.text('Profil'));
      await settle(tester, frames: 6);
      expect(find.byType(TextField), findsNothing);

      auth
        ..isLoggedIn = true
        ..justSignedIn = true
        ..token = 'test-token'
        ..userId = 42
        ..displayName = 'Test Korisnik';
      auth.notifyListeners();
      await settle(tester, frames: 6);

      // Explore's search field only exists on the Explore tab.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a restored session leaves the tab alone', (tester) async {
      // restore() flips isLoggedIn at launch too, and by then a deep
      // link may already have chosen a tab. Only an interactive sign-in
      // sets justSignedIn, and only that should move anybody.
      final auth = AuthState()..isRestoring = false;
      await openShell(tester, auth: auth);

      await tester.tap(find.text('Profil'));
      await settle(tester, frames: 6);

      auth
        ..isLoggedIn = true
        ..token = 'test-token'
        ..userId = 42;
      auth.notifyListeners();
      await settle(tester, frames: 6);

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('the search row', () {
    // Both of these come from measuring the row rather than looking at
    // it. Nothing overflowed, nothing threw, and the layout suite was
    // green the whole time -- the field was simply being squeezed.
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('keeps the field usable at text scale $scale',
          (tester) async {
        useBackend(healthy());
        await usePhoneScreen(tester);
        await tester.pumpWidget(harness(const RootShell(), textScale: scale));
        await settle(tester);

        final field = tester.getRect(find.byType(TextField));
        final screen = tester.view.physicalSize.width / tester.view.devicePixelRatio;

        // The city picker used to take whatever its label needed and
        // Expanded handed over what was left, which at scale 1.3 was 92
        // logical pixels -- narrower than the search icon and the clear
        // button together.
        expect(
          field.width,
          greaterThan(screen * 0.45),
          reason: 'the search field is ${field.width.round()}pt of $screen',
        );

        // And it has to be reachable without scrolling. At 1.6 the hero
        // headline grew until the whole row sat below the fold and was
        // never built at all.
        expect(field.bottom, lessThan(844));
      });
    }

    testWidgets('a long city name is ellipsised, not given the whole row',
        (tester) async {
      useBackend(healthy());
      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const RootShell()));
      await settle(tester);

      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      await tester.tap(find.byIcon(Icons.location_on));
      await settle(tester, frames: 8);
      await tester.tap(find.text('Mostar').last);
      await settle(tester, frames: 8);

      // A shorter name gives width back to the field, which is right.
      // What must not happen is the other direction: the floor holds
      // whatever is chosen.
      expect(tester.getRect(find.byType(TextField)).width,
          greaterThan(screen * 0.45));
    });
  });

  group('switching tabs', () {
    testWidgets('keeps what you typed on Explore', (tester) async {
      // The shell used to swap the child widget outright, which replaces
      // the element and throws away the screen's State. Typing a search,
      // glancing at Appointments and coming back lost the search, the
      // scroll position, and re-fetched the whole clinic list.
      await openShell(tester);

      await tester.enterText(find.byType(TextField), 'Mostar');
      await settle(tester, frames: 4);
      expect(find.textContaining('Happy Paws'), findsNothing);

      await tester.tap(find.text('Termini'));
      await settle(tester, frames: 6);
      await tester.tap(find.text('Istraži'));
      await settle(tester, frames: 6);

      expect(find.text('Mostar'), findsWidgets);
      expect(find.textContaining('Happy Paws'), findsNothing);
    });

    testWidgets('does not build a tab nobody has opened', (tester) async {
      // An IndexedStack keeps every child alive, which is the point, but
      // it also builds them all on the first frame -- a signed-in launch
      // would fire the appointments request before anyone asked for it.
      await openShell(tester);

      expect(backend.calls.where((c) => c.url.path.contains('Appointment')),
          isEmpty);

      await tester.tap(find.text('Termini'));
      await settle(tester, frames: 6);

      expect(backend.calls.where((c) => c.url.path.contains('Appointment')),
          isNotEmpty);
    });

    testWidgets('asks a tab it kept alive for fresh data', (tester) async {
      // The other side of keeping tabs alive: the data on one is as old
      // as the last time it was looked at. Book a visit from Explore,
      // tap Termini, and the new appointment would not be there.
      await openShell(tester);

      await tester.tap(find.text('Termini'));
      await settle(tester, frames: 6);
      final first =
          backend.calls.where((c) => c.url.path.contains('Appointment')).length;
      expect(first, greaterThan(0));

      await tester.tap(find.text('Istraži'));
      await settle(tester, frames: 6);
      await tester.tap(find.text('Termini'));
      await settle(tester, frames: 6);

      expect(
        backend.calls.where((c) => c.url.path.contains('Appointment')).length,
        greaterThan(first),
      );
    });
  });

  group('the back gesture', () {
    testWidgets('returns to Explore before it leaves the app', (tester) async {
      // On Android, back from Profile closed VetNow outright, which is
      // not what the gesture means anywhere else on the phone.
      await openShell(tester);

      await tester.tap(find.text('Profil'));
      await settle(tester, frames: 6);
      expect(find.byType(TextField), findsNothing);

      final popped = await tester.binding.handlePopRoute();
      await settle(tester, frames: 6);

      expect(popped, isTrue, reason: 'the shell handled it rather than exiting');
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('leaves the app when there is nowhere further back',
        (tester) async {
      await openShell(tester);

      expect(await tester.binding.handlePopRoute(), isFalse);
    });
  });
}
