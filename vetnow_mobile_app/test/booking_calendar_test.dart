// Choosing a day, and not being allowed to choose a time that has gone.
//
// The screen used to ask the backend for today and nothing else. The
// endpoint always took a date — it was simply never given one — so
// "tomorrow" was not something the app could express, and a whole day of
// slots came back unfiltered. At five in the afternoon it offered four
// o'clock, took the booking, and filed it under past visits.

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/l10n/service_catalog.dart';
import 'package:vetnow_mobile/models/vet_service.dart';
import 'package:vetnow_mobile/models/vet_station.dart';
import 'package:vetnow_mobile/screens/booking_screen.dart';

import 'support/fake_backend.dart';

/// Runs [body] as though it were [hour] o'clock that day.
Future<void> at(int hour, Future<void> Function() body) =>
    withClock(Clock.fixed(DateTime(2026, 9, 16, hour)), body);

/// Slots at 09:00, 16:00 and 18:30 on whichever date was asked for.
///
/// Reading the query rather than ignoring it is the point: the whole
/// bug was that the screen never sent one.
List<Map<String, dynamic>> slotsFor(String? date) {
  final day = DateTime.parse(date ?? '2026-09-16');
  Map<String, dynamic> one(int id, int hour, int minute) => {
        'id': id,
        'appointmentTime': '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}',
        'slotDateTime':
            DateTime(day.year, day.month, day.day, hour, minute).toIso8601String(),
      };

  return [one(1, 9, 0), one(2, 16, 0), one(3, 18, 30)];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(resetBackend);

  late FakeBackend backend;

  FakeBackend healthy() => FakeBackend({
        'Employee/GetByVetStationId': (_) => {
              'dataItems': [
                {'id': 7, 'firstName': 'Amina', 'lastName': 'Hodžić', 'roleId': 4},
              ],
            },
        'Animal/GetByOwnerId': (_) => animals(),
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'TimeSlot': (r) => slotsFor(r.url.queryParameters['date']),
        'VetStation/OpeningHours': (_) => {
              'vetStationId': 1,
              'hasSchedule': true,
              'days': [
                for (var i = 0; i < 7; i++)
                  {
                    'day': 'Day$i',
                    // Sunday shut, which is day index 6.
                    'closed': i == 6,
                    'opensAt': '08:00',
                    'closesAt': '20:00',
                    'staffCount': 2,
                  },
              ],
            },
      });

  Future<void> openBooking(WidgetTester tester) async {
    backend = healthy();
    useBackend(backend);

    final rows = stations()['vetStations']! as List<dynamic>;
    final station = VetStation.fromJson(rows.first as Map<String, dynamic>);
    await usePhoneScreen(tester);
    await tester.pumpWidget(harness(
      Builder(
        builder: (context) => BookingScreen(
          station: station,
          services: [ServiceCatalog.service(context, ServiceKind.checkup)],
          preselected: ServiceCatalog.service(context, ServiceKind.checkup),
        ),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// Every date the screen actually asked the backend about.
  List<String> datesAsked() => backend.calls
      .where((c) => c.url.path.contains('TimeSlot'))
      .map((c) => c.url.queryParameters['date'] ?? '')
      .toList();

  testWidgets('asks for today on open', (tester) async {
    await at(8, () async {
      await openBooking(tester);
      expect(datesAsked(), contains('2026-09-16'));
    });
  });

  testWidgets('a time that has gone by is not offered', (tester) async {
    // The reported bug, from the other end: at 17:00, 09:00 and 16:00
    // must not be on screen at all.
    await at(17, () async {
      await openBooking(tester);

      expect(find.text('18:30'), findsOneWidget);
      expect(find.text('16:00'), findsNothing);
      expect(find.text('09:00'), findsNothing);
    });
  });

  testWidgets('the whole day is offered first thing in the morning',
      (tester) async {
    await at(7, () async {
      await openBooking(tester);

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
      expect(find.text('18:30'), findsOneWidget);
    });
  });

  testWidgets('times are grouped by stretch of day', (tester) async {
    await at(7, () async {
      await openBooking(tester);

      expect(find.text('JUTRO'), findsOneWidget);
      expect(find.text('POSLIJEPODNE'), findsOneWidget);
      expect(find.text('VEČE'), findsOneWidget);
    });
  });

  testWidgets('says when the soonest free time is', (tester) async {
    await at(7, () async {
      await openBooking(tester);

      expect(find.textContaining('Najranije slobodno'), findsOneWidget);
      expect(find.textContaining('danas 09:00'), findsOneWidget);
    });
  });

  testWidgets('tapping tomorrow asks the backend about tomorrow',
      (tester) async {
    await at(8, () async {
      await openBooking(tester);

      // The 17th, the second capsule in the strip.
      await tester.tap(find.text('17'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(datesAsked(), contains('2026-09-17'));
    });
  });

  testWidgets('a day the clinic is shut cannot be picked', (tester) async {
    await at(8, () async {
      await openBooking(tester);

      // The 20th is the Sunday inside the strip, and the fixture has
      // Sunday closed.
      await tester.tap(find.text('20'), warnIfMissed: false);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(datesAsked(), isNot(contains('2026-09-20')));
    });
  });

  testWidgets('the summary says which day, not always "danas"',
      (tester) async {
    await at(8, () async {
      await openBooking(tester);

      await tester.tap(find.text('17'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await tester.tap(find.text('09:00'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      // The summary sits at the foot of a lazy list, so it is not
      // built until it is scrolled to.
      await scrollToBottom(tester);

      // It used to read "Danas u 09:00" whatever day was chosen, because
      // the screen could only ever mean today.
      expect(find.textContaining('sutra u 09:00'), findsOneWidget);
    });
  });
}
