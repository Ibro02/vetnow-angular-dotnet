// The screens behind the login, rendered end to end against a fake
// backend.
//
// These had almost no coverage until now, and for a mundane reason: each
// one starts by asking the server for something, so there was no way to
// build one in a test without a server. They are also the screens nobody
// has ever seen driven — the browser harness cannot type into a Flutter
// text field reliably, so the login was never got past by hand either.
//
// So this is the first time Pets, Appointments and Profile have been run
// at all outside someone's imagination, and the cases below lean towards
// the things that would be embarrassing in front of a user: a spinner
// that never ends, an error with no way out, a list that silently drops
// half its rows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/my_appointments_screen.dart';
import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/screens/profile_screen.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';
import 'package:vetnow_mobile/widgets/state_views.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The species list is cached for the whole session by design; left
    // alone it would leak one test's answers into the next.
    SpeciesApiService.invalidate();
  });

  tearDown(() {
    resetBackend();
    SpeciesApiService.invalidate();
  });

  group('Pets', () {
    FakeBackend healthy() => FakeBackend({
          'SpeciesGetAll': (_) => speciesEnvelope(),
          'Animal/GetByOwnerId': (_) => animals(),
          'Appointment/GetByCustomerId': (_) => [appointment()],
        });

    testWidgets('lists the pets the backend returned', (tester) async {
      useBackend(healthy());

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rex'), findsWidgets);
      expect(find.text('Mica'), findsWidgets);
    });

    testWidgets('joins each pet to its species name', (tester) async {
      // The species list and the pets come back from two separate
      // requests fired together; if the join is wrong the names are
      // simply blank, and blank reads as "no species recorded".
      useBackend(healthy());

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pas'), findsWidgets);
    });

    testWidgets('sends the session token, and only to the endpoints that '
        'need one', (tester) async {
      final backend = healthy();
      useBackend(backend);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(backend.tokenFor('Animal/GetByOwnerId'), 'test-token');
    });

    testWidgets('a dropped connection gives an error with a way out, not a '
        'spinner forever', (tester) async {
      final backend = healthy()..offline.add('Animal/GetByOwnerId');
      useBackend(backend);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      final l10n = await bosnian();
      expect(find.text(l10n.retry), findsOneWidget);
    });

    testWidgets('the retry button actually asks again', (tester) async {
      final backend = healthy()..offline.add('Animal/GetByOwnerId');
      useBackend(backend);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      final before = backend.calls.length;
      final l10n = await bosnian();
      await tester.tap(find.text(l10n.retry));
      await tester.pumpAndSettle();

      expect(backend.calls.length, greaterThan(before));
    });

    testWidgets('no pets is an empty state, not an error', (tester) async {
      // The two used to look identical on this screen, which meant
      // someone who simply had not added a pet yet was told something
      // had gone wrong.
      useBackend(FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => <Map<String, dynamic>>[],
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
      }));

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('a failed visit count does not empty the pet list',
        (tester) async {
      // Visit counts are decoration. The list is the screen.
      final backend = healthy()..broken.add('Appointment/GetByCustomerId');
      useBackend(backend);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Rex'), findsWidgets);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('a guest is asked to sign in rather than shown an error',
        (tester) async {
      useBackend(healthy());

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen(), signedIn: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Nothing was requested on behalf of nobody.
      expect(find.text('Rex'), findsNothing);
    });
  });

  group('Appointments', () {
    testWidgets('shows a booked visit with its clinic and pet',
        (tester) async {
      useBackend(FakeBackend({
        'Appointment/GetByCustomerId': (_) => [appointment()],
      }));

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Happy Paws'), findsWidgets);
      expect(find.textContaining('Rex'), findsWidgets);
    });

    // Split into two tests rather than two halves of one on purpose:
    // pumping the same widget again reuses the State, so initState never
    // re-runs and the second half would quietly assert against the first
    // half's data.
    testWidgets('an empty calendar is an empty state', (tester) async {
      useBackend(FakeBackend({
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
      }));

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsNothing);
      expect(find.byType(EmptyStateView), findsWidgets);
    });

    testWidgets('a dropped connection is not', (tester) async {
      // These used to render identically: a failed request was passed
      // through as the empty-state text, so "you have nothing booked" and
      // "we could not ask" were the same screen.
      useBackend(FakeBackend({})..offline.add('Appointment'));

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
    });

    testWidgets('a server error shows the server\'s own words',
        (tester) async {
      final backend = FakeBackend({})..broken.add('Appointment');
      useBackend(backend);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server je pao'), findsOneWidget);
    });

    testWidgets('never settles into a permanent spinner', (tester) async {
      // Whatever happens, the screen has to stop loading. This is the
      // failure mode that looks like the app is broken rather than the
      // network being down.
      for (final backend in [
        FakeBackend({'Appointment/GetByCustomerId': (_) => [appointment()]}),
        FakeBackend({'Appointment/GetByCustomerId': (_) => <dynamic>[]}),
        FakeBackend({})..offline.add('Appointment'),
        FakeBackend({})..broken.add('Appointment'),
      ]) {
        useBackend(backend);
        await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Profile', () {
    testWidgets('greets the signed-in person by name', (tester) async {
      useBackend(FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => animals(),
        'ProfileEndpoint': (_) => {
              'id': 42,
              'firstName': 'Test',
              'lastName': 'Korisnik',
              'email': 'test@vetnow.ba',
            },
      }));

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test'), findsWidgets);
    });

    testWidgets('the settings rows all lead somewhere', (tester) async {
      // "Help & support" used to be a row that did nothing when tapped.
      useBackend(FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => animals(),
        'ProfileEndpoint': (_) => {'id': 42, 'firstName': 'Test'},
      }));
      final l10n = await bosnian();

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const ProfileScreen()));
      await tester.pumpAndSettle();

      // The settings list is below the fold on a phone, so this row is
      // only reachable by scrolling. scrollUntilVisible is no use here:
      // the list is built eagerly, so the finder matches immediately and
      // it never scrolls at all, then taps off-screen.
      await scrollToBottom(tester);
      // The row, not the label inside it: the tap target is the InkWell
      // wrapping the whole row.
      await tester.tap(find.ancestor(
        of: find.text(l10n.helpSupport),
        matching: find.byType(InkWell),
      ).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.diagnosticsTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('diagnostics reports the build it is actually running',
        (tester) async {
      useBackend(FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => animals(),
        'ProfileEndpoint': (_) => {'id': 42, 'firstName': 'Test'},
      }));
      final l10n = await bosnian();

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const ProfileScreen()));
      await tester.pumpAndSettle();
      await scrollToBottom(tester);
      await tester.tap(find.ancestor(
        of: find.text(l10n.helpSupport),
        matching: find.byType(InkWell),
      ).last);
      await tester.pumpAndSettle();

      expect(find.text(l10n.diagnosticsVersion), findsOneWidget);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
    });
  });
}
