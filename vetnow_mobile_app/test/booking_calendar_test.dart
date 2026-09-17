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
        // The screen asks the trade-specific endpoint for whichever
        // service is chosen, so the vet one has to be routed too — and
        // before the general one, since FakeBackend matches on a path
        // substring in insertion order.
        'Employee/GetVetsByVetStationId': (_) => {
              'dataItems': [
                {'id': 7, 'firstName': 'Amina', 'lastName': 'Hodžić', 'roleId': 4},
              ],
            },
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

  /// Opens the screen against a backend the caller has already set
  /// up, for the cases that need an unusual answer from it.
  Future<void> openBookingWith(WidgetTester tester, FakeBackend prepared) async {
    useBackend(prepared);

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
    for (var i = 0; i < 14; i++) {
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

  testWidgets('says nothing about the soonest slot when you are looking at it',
      (tester) async {
    // The banner used to announce the first slot of whichever day was
    // on screen — which is the pill immediately below it. A line that
    // tells you something you can already see is furniture.
    await at(7, () async {
      await openBooking(tester);

      expect(find.textContaining('Najranije slobodno'), findsNothing);
      expect(find.textContaining('Prvi termin'), findsNothing);
    });
  });

  testWidgets('points at the soonest opening when it is on another day',
      (tester) async {
    // Today full, the 18th free. That is worth a line, because it is
    // the one thing on this screen nobody can work out by looking.
    backend = healthy();
    backend.routes['TimeSlot'] = (r) {
      final date = r.url.queryParameters['date'];
      return date == '2026-09-18' ? slotsFor(date) : <Map<String, dynamic>>[];
    };

    await at(7, () async {
      await openBookingWith(tester, backend);

      expect(find.textContaining('Prvi termin'), findsOneWidget);
      expect(find.textContaining('09:00'), findsWidgets);
    });
  });

  testWidgets('one tap on it moves the day and picks the time',
      (tester) async {
    backend = healthy();
    backend.routes['TimeSlot'] = (r) {
      final date = r.url.queryParameters['date'];
      return date == '2026-09-18' ? slotsFor(date) : <Map<String, dynamic>>[];
    };

    await at(7, () async {
      await openBookingWith(tester, backend);

      await tester.tap(find.textContaining('Prvi termin'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(datesAsked(), contains('2026-09-18'));

      // And the slot is chosen rather than merely on screen waiting
      // to be found: the summary at the foot of the form names it.
      for (var i = 0; i < 14; i++) {
        await tester.dragFrom(const Offset(200, 700), const Offset(0, -240));
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(find.textContaining('09:00'), findsWidgets);
      expect(find.textContaining('septembar'), findsWidgets);
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

  group('choosing a pet', () {
    /// The placeholder inside the pet filter. Shared with the Pets
    /// screen, which has had the same search for a while  no reason
    /// for the booking flow to invent a second wording for it.
    const hint = 'Pretraži po imenu…';

    /// [count] pets, named so the search has something to bite on.
    List<Map<String, dynamic>> manyPets(int count) => [
          for (var i = 0; i < count; i++)
            {
              'id': 100 + i,
              'name': i == 0 ? 'Mica' : 'Rex$i',
              'animalSpeciesId': 1,
              'birthDate': '2022-01-01T00:00:00',
              'isFavourite': i == 3,
            },
        ];

    Future<void> openWith(WidgetTester tester, int petCount) async {
      backend = healthy();
      backend.routes['Animal/GetByOwnerId'] = (_) => manyPets(petCount);
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

    /// Scrolls until [finder] is on screen.
    ///
    /// Not scrollToBottom: the form is a lazy ListView, so anything
    /// scrolled past is disposed and find.text stops seeing it. The pet
    /// search sits above nine pet cards, which is a long way above the
    /// bottom of the page.
    Future<void> reveal(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 14 && finder.evaluate().isEmpty; i++) {
        // From a point near the bottom of the screen rather than at
        // find.byType(Scrollable).first. The day strip is a horizontal
        // ListView and therefore a Scrollable too, and dragging it
        // upwards does exactly nothing — which looked like a page that
        // would not scroll.
        await tester.dragFrom(const Offset(200, 700), const Offset(0, -240));
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('a short list gets no search box', (tester) async {
      // Somebody with two animals does not need one and should not be
      // shown one.
      await at(8, () async {
        await openWith(tester, 2);
        await reveal(tester, find.text('Mica'));

        expect(find.text(hint), findsNothing);
      });
    });

    testWidgets('a long list does', (tester) async {
      await at(8, () async {
        await openWith(tester, 9);
        await reveal(tester, find.text(hint));

        expect(find.text(hint), findsOneWidget);
      });
    });

    testWidgets('typing narrows the list', (tester) async {
      await at(8, () async {
        await openWith(tester, 9);
        await reveal(tester, find.text(hint));

        await tester.enterText(
            find.widgetWithText(TextField, hint), 'Mica');
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }

        // findsWidgets, not findsOneWidget: "Mica" is now also the
        // contents of the field that was typed into.
        expect(find.text('Mica'), findsWidgets);
        expect(find.text('Rex1'), findsNothing);
      });
    });

    testWidgets('a search that matches nothing says so', (tester) async {
      // Rather than an empty gap where the list was, which reads as the
      // pets having been lost.
      await at(8, () async {
        await openWith(tester, 9);
        await reveal(tester, find.text(hint));

        await tester.enterText(
            find.widgetWithText(TextField, hint), 'zzz');
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }

        expect(find.text('Nijedan ljubimac ne odgovara pretrazi.'), findsOneWidget);
      });
    });

    testWidgets('favourites come first', (tester) async {
      // A pet marked favourite is the one being booked for.
      await at(8, () async {
        await openWith(tester, 9);
        // Revealed by a card rather than by the search box: the box
        // sits above the list, so stopping there leaves every card
        // still below the fold and unbuilt.
        await reveal(tester, find.text('Rex1'));

        // Read in tree order rather than by position: the list is
        // lazy, so comparing two rectangles only works when both
        // happen to be built, and which ones are depends on where the
        // scroll stopped.
        final names = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((s) => s == 'Mica' || RegExp(r'^Rex[0-9]+$').hasMatch(s))
            .toList();

        expect(names, contains('Rex3'), reason: 'built order was $names');
        expect(
          names.indexOf('Rex3'),
          lessThan(names.indexOf('Mica')),
          reason: 'built order was $names',
        );
      });
    });
  });
}
