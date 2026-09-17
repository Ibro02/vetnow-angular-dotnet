// What the app can still show with no connection.
//
// ClinicCache did this for Explore and stopped there, so a phone in a
// lift, in a basement or out of credit opened Pets and Termini to an
// error page — built on data the app had downloaded and then thrown
// away. Somebody at a clinic counter trying to check when their
// appointment is has exactly the wrong problem for that.
//
// The cases below are mostly about the rules that keep a cache from
// becoming a liar: how old is too old, whose data is it, and what
// happens when it is corrupt.

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/my_appointments_screen.dart';
import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/services/account_cache.dart';
import 'package:vetnow_mobile/services/appointment_api_service.dart';
import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/pets_api_service.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';

import 'support/fake_backend.dart';

final _now = DateTime(2026, 9, 17, 10);

T at<T>(DateTime when, T Function() body) =>
    withClock(Clock.fixed(when), body);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
  });

  tearDown(() {
    resetBackend();
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
  });

  group('AccountCache', () {
    test('what went in comes back out', () async {
      await at(_now, () => AccountCache.save('pets', 42, [
            {'id': 1, 'name': 'Rex'},
          ]));

      final rows = await at(_now, () => AccountCache.read('pets', 42));

      expect(rows, hasLength(1));
      expect(rows!.first['name'], 'Rex');
    });

    test('is kept per account', () async {
      // Two people share a phone more often than anyone plans for, and
      // one of them seeing the other's animals is not a cache miss, it
      // is a leak.
      await at(_now, () => AccountCache.save('pets', 42, [
            {'id': 1, 'name': 'Rex'},
          ]));

      expect(await at(_now, () => AccountCache.read('pets', 99)), isNull);
    });

    test('pets and appointments do not share a drawer', () async {
      await at(_now, () => AccountCache.save('pets', 42, [
            {'id': 1, 'name': 'Rex'},
          ]));

      expect(await at(_now, () => AccountCache.read('appointments', 42)), isNull);
    });

    test('anything older than three days is ignored', () async {
      // Not deleted — ignored. An appointment list from last week is not
      // a helpful thing to be looking at, whatever the alternative.
      await at(_now, () => AccountCache.save('appointments', 42, [
            {'id': 7},
          ]));

      final later = _now.add(const Duration(days: 3, hours: 1));
      expect(await at(later, () => AccountCache.read('appointments', 42)), isNull);
    });

    test('just under three days is still good', () async {
      await at(_now, () => AccountCache.save('appointments', 42, [
            {'id': 7},
          ]));

      final later = _now.add(const Duration(days: 2, hours: 23));
      expect(await at(later, () => AccountCache.read('appointments', 42)), hasLength(1));
    });

    test('a clock that moved backwards is unusable, not infinitely fresh',
        () async {
      await at(_now, () => AccountCache.save('pets', 42, [
            {'id': 1},
          ]));

      final earlier = _now.subtract(const Duration(days: 1));
      expect(await at(earlier, () => AccountCache.read('pets', 42)), isNull);
    });

    test('a corrupt entry behaves exactly like no entry', () async {
      SharedPreferences.setMockInitialValues({
        'vetnow.cache.pets.42': 'this is not json',
        'vetnow.cache.pets.42.savedAt': _now.millisecondsSinceEpoch,
      });

      expect(await at(_now, () => AccountCache.read('pets', 42)), isNull);
    });

    test('signing out forgets that account and leaves the others alone',
        () async {
      await at(_now, () async {
        await AccountCache.save('pets', 42, [
          {'id': 1},
        ]);
        await AccountCache.save('pets', 99, [
          {'id': 2},
        ]);
        await AccountCache.clearFor(42);
      });

      expect(await at(_now, () => AccountCache.read('pets', 42)), isNull);
      expect(await at(_now, () => AccountCache.read('pets', 99)), hasLength(1));
    });
  });

  group('the screens', () {
    FakeBackend healthy() => FakeBackend({
          'SpeciesGetAll': (_) => speciesEnvelope(),
          'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
          'Animal/GetByOwnerId': (_) => animals(),
          'Appointment/GetByCustomerId': (_) => [appointment()],
        });

    Future<void> settle(WidgetTester tester, {int frames = 10}) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('a good load fills the cache', (tester) async {
      useBackend(healthy());
      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await settle(tester);

      expect(await PetsApiService.cachedFor(42), isNotNull);
    });

    testWidgets('pets survive the network going away', (tester) async {
      // Loaded once, then the request fails on a later visit. The pets
      // are still on disk and still worth showing.
      useBackend(healthy());
      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await settle(tester);
      expect(find.text('Rex'), findsWidgets);

      final dead = healthy()..offline.add('Animal/GetByOwnerId');
      useBackend(dead);

      // A blank frame in between, so the screen is built fresh rather
      // than reusing the State that already has the pets in it — which
      // would test nothing at all.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(harness(const PetsScreen()));
      await settle(tester);

      expect(find.text('Rex'), findsWidgets);
      // And says where they came from, rather than passing three-day-old
      // data off as current.
      expect(find.textContaining('Nema veze sa serverom'), findsOneWidget);
    });

    testWidgets('appointments survive it too', (tester) async {
      useBackend(healthy());
      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await settle(tester);

      expect(await AppointmentApiService.cachedFor(42), isNotNull);

      final dead = healthy()..offline.add('Appointment/GetByCustomerId');
      useBackend(dead);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(harness(const MyAppointmentsScreen()));
      await settle(tester);

      expect(find.textContaining('Nema veze sa serverom'), findsOneWidget);
    });

    testWidgets('with nothing cached, an error is still an error',
        (tester) async {
      // The cache is a fallback, not a way of hiding failures.
      final dead = healthy()..offline.add('Animal/GetByOwnerId');
      useBackend(dead);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      await settle(tester);

      expect(find.textContaining('Nema veze sa serverom'), findsNothing);
    });
  });
}
