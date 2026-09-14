// Opening hours: parsing what the server sends, and the card that shows it.
//
// The value of this screen element is entirely in it being true — it
// replaced a line of text that claimed the same hours for every clinic and
// was an hour and a half off — so the states worth pinning down are the
// ones where it could quietly start lying again: a clinic with no schedule
// rendering as if it had one, or a closed day rendering as open.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/opening_hours.dart';
import 'package:vetnow_mobile/widgets/opening_hours_card.dart';

const _payload = {
  'vetStationId': 1,
  'hasSchedule': true,
  'isOpenNow': true,
  'todayOpensAt': '08:00',
  'todayClosesAt': '16:00',
  'days': [
    {'day': 'Monday', 'closed': false, 'opensAt': '08:00', 'closesAt': '16:00', 'staffCount': 5},
    {'day': 'Tuesday', 'closed': false, 'opensAt': '08:00', 'closesAt': '16:00', 'staffCount': 5},
    {'day': 'Wednesday', 'closed': false, 'opensAt': '08:00', 'closesAt': '16:00', 'staffCount': 5},
    {'day': 'Thursday', 'closed': false, 'opensAt': '08:00', 'closesAt': '16:00', 'staffCount': 5},
    {'day': 'Friday', 'closed': false, 'opensAt': '08:00', 'closesAt': '16:00', 'staffCount': 5},
    {'day': 'Saturday', 'closed': false, 'opensAt': '09:00', 'closesAt': '13:00', 'staffCount': 1},
    {'day': 'Sunday', 'closed': true, 'opensAt': null, 'closesAt': null, 'staffCount': 0},
  ],
};

/// The card lives inside a phone's page padding, so [width] defaults to what
/// it actually gets on a 375pt screen. The first version of the header row
/// laid out fine at the test surface's default width and truncated the hours
/// to "08:00 – 1…" on a real phone.
Future<void> pumpCard(
  WidgetTester tester, {
  OpeningHours? hours,
  bool isLoading = false,
  double width = 343,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: OpeningHoursCard(hours: hours, isLoading: isLoading),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('OpeningHours.fromJson', () {
    test('keeps the week in the order the server sent it', () {
      final hours = OpeningHours.fromJson(Map<String, dynamic>.from(_payload));
      expect(hours.days.length, 7);
      expect(hours.days.first.day, 'Monday');
      expect(hours.days.last.day, 'Sunday');
    });

    test('a closed day has no range', () {
      final hours = OpeningHours.fromJson(Map<String, dynamic>.from(_payload));
      final sunday = hours.days.last;
      expect(sunday.closed, isTrue);
      expect(sunday.range, isNull);
    });

    test('an open day formats its range', () {
      final hours = OpeningHours.fromJson(Map<String, dynamic>.from(_payload));
      expect(hours.days.first.range, '08:00 – 16:00');
      expect(hours.todayRange, '08:00 – 16:00');
    });

    test('a clinic with no schedule parses without inventing hours', () {
      final hours = OpeningHours.fromJson(const {
        'vetStationId': 9,
        'hasSchedule': false,
        'isOpenNow': false,
        'todayOpensAt': null,
        'todayClosesAt': null,
        'days': <dynamic>[],
      });

      expect(hours.hasSchedule, isFalse);
      expect(hours.isOpenNow, isFalse);
      expect(hours.todayRange, isNull);
    });

    test('a response missing every optional field still parses', () {
      final hours = OpeningHours.fromJson(const {'vetStationId': 1});
      expect(hours.days, isEmpty);
      expect(hours.hasSchedule, isFalse);
    });
  });

  group('OpeningHoursCard', () {
    testWidgets('an open clinic says so, with today\'s hours', (tester) async {
      await pumpCard(tester, hours: OpeningHours.fromJson(Map<String, dynamic>.from(_payload)));

      expect(find.text('Otvoreno sada'), findsOneWidget);
      expect(find.text('· 08:00 – 16:00'), findsOneWidget);
    });

    testWidgets('the hours still fit on a narrow phone', (tester) async {
      // 320pt is the narrowest phone worth supporting. The header packs a
      // status dot, a long Bosnian status string, the hours and a chevron
      // into one row, so this is where it breaks first.
      await pumpCard(
        tester,
        hours: OpeningHours.fromJson(Map<String, dynamic>.from(_payload)),
        width: 288,
      );

      expect(tester.takeException(), isNull, reason: 'no overflow stripes');
      expect(find.text('· 08:00 – 16:00'), findsOneWidget);
    });

    testWidgets('a closed clinic says closed', (tester) async {
      final closed = Map<String, dynamic>.from(_payload)..['isOpenNow'] = false;
      await pumpCard(tester, hours: OpeningHours.fromJson(closed));

      expect(find.text('Trenutno zatvoreno'), findsOneWidget);
      expect(find.text('Otvoreno sada'), findsNothing);
    });

    testWidgets('the week is hidden until the card is tapped', (tester) async {
      await pumpCard(tester, hours: OpeningHours.fromJson(Map<String, dynamic>.from(_payload)));

      expect(find.text('Ponedjeljak'), findsNothing);

      await tester.tap(find.text('Otvoreno sada'));
      await tester.pumpAndSettle();

      expect(find.text('Ponedjeljak'), findsOneWidget);
      expect(find.text('Nedjelja'), findsOneWidget);
      // Saturday genuinely differs from the weekdays in the fixture; a card
      // that collapsed every day into one range would lose that.
      expect(find.text('09:00 – 13:00'), findsOneWidget);
      // And the closed day reads as closed, not as a blank row.
      expect(find.text('Zatvoreno'), findsOneWidget);
    });

    testWidgets('a clinic with no schedule says so instead of showing zeros',
        (tester) async {
      await pumpCard(
        tester,
        hours: OpeningHours.fromJson(const {'vetStationId': 9, 'hasSchedule': false, 'days': <dynamic>[]}),
      );

      expect(find.text('Radno vrijeme još nije uneseno.'), findsOneWidget);
      expect(find.text('Trenutno zatvoreno'), findsNothing);
    });

    testWidgets('a failed load looks the same as no schedule', (tester) async {
      // `hours: null` is what the screen is left holding when the request
      // fails. Claiming "closed" there would be a guess presented as fact.
      await pumpCard(tester, hours: null);
      expect(find.text('Radno vrijeme još nije uneseno.'), findsOneWidget);
    });

    testWidgets('while loading it claims nothing at all', (tester) async {
      await pumpCard(tester, hours: null, isLoading: true);

      expect(find.text('Trenutno zatvoreno'), findsNothing);
      expect(find.text('Otvoreno sada'), findsNothing);
      expect(find.text('Radno vrijeme još nije uneseno.'), findsNothing);
    });
  });
}
