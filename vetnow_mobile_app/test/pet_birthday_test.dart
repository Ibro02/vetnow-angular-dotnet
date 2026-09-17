// Pet age and birthdays.
//
// Date arithmetic is where this kind of feature goes quietly wrong: a
// birthday that has just passed rolling to next year a day early, a
// 29 February pet never having one at all, or a dog turning "0 years".
// Every case here is pinned to a fixed `asOf` date so the suite means
// the same thing in December as it does today.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/pet.dart';
import 'package:vetnow_mobile/widgets/pet_age.dart';

Pet pet({DateTime? born, String name = 'Max', String species = 'Dog'}) => Pet(
      id: 1,
      name: name,
      species: species,
      breed: 'Mix',
      birthDate: born,
    );

Future<void> pumpBadge(WidgetTester tester, Pet p, {DateTime? asOf}) async {
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
      home: Scaffold(body: Center(child: PetBirthdayBadge(pet: p, asOf: asOf))),
    ),
  );
  await tester.pump();
}

void main() {
  // A Monday, deliberately mid-month and mid-year.
  final today = DateTime(2026, 9, 14);

  group('age', () {
    test('counts completed years, not started ones', () {
      // Born 2019-09-15: the day before the seventh birthday is still six.
      expect(pet(born: DateTime(2019, 9, 15)).ageInYears(today), 6);
      expect(pet(born: DateTime(2019, 9, 14)).ageInYears(today), 7);
      expect(pet(born: DateTime(2019, 9, 13)).ageInYears(today), 7);
    });

    test('a pet under one is measured in months, not in zero years', () {
      final puppy = pet(born: DateTime(2026, 1, 20));
      expect(puppy.ageInYears(today), isNull);
      expect(puppy.ageInMonths(today), 7);
    });

    test('months stop being reported once a pet turns one', () {
      final grown = pet(born: DateTime(2024, 1, 20));
      expect(grown.ageInYears(today), 2);
      expect(grown.ageInMonths(today), isNull);
    });

    test('a newborn is zero months, never negative', () {
      expect(pet(born: DateTime(2026, 9, 10)).ageInMonths(today), 0);
    });

    test('no birth date means no age, rather than a wrong one', () {
      expect(pet(born: null).ageInYears(today), isNull);
      expect(pet(born: null).ageInMonths(today), isNull);
      expect(pet(born: null).daysUntilBirthday(today), isNull);
    });
  });

  group('next birthday', () {
    test('a birthday still to come this year stays this year', () {
      final p = pet(born: DateTime(2019, 11, 29));
      expect(p.nextBirthday(today), DateTime(2026, 11, 29));
      expect(p.daysUntilBirthday(today), 76);
      expect(p.turningAge(today), 7);
    });

    test('a birthday already past rolls to next year', () {
      final p = pet(born: DateTime(2020, 8, 21));
      expect(p.nextBirthday(today), DateTime(2027, 8, 21));
      expect(p.turningAge(today), 7);
    });

    test('today is the birthday, not one already missed', () {
      final p = pet(born: DateTime(2019, 9, 14));
      expect(p.daysUntilBirthday(today), 0);
      expect(p.isBirthdayToday(today), isTrue);
      expect(p.turningAge(today), 7);
    });

    test('tomorrow is one day away', () {
      expect(pet(born: DateTime(2019, 9, 15)).daysUntilBirthday(today), 1);
    });

    test('a 29 February pet still has a birthday in a common year', () {
      // 2027 is not a leap year; falling back to the 28th is better than
      // silently landing on 1 March, and far better than never matching.
      final p = pet(born: DateTime(2020, 2, 29));
      expect(p.nextBirthday(today), DateTime(2027, 2, 28));

      // In a leap year it is the 29th again.
      expect(p.nextBirthday(DateTime(2027, 12, 1)), DateTime(2028, 2, 29));
    });

    test('the near-birthday window is a fortnight', () {
      expect(pet(born: DateTime(2019, 9, 28)).birthdayIsNear(today), isTrue); // 14 days
      expect(pet(born: DateTime(2019, 9, 29)).birthdayIsNear(today), isFalse); // 15
      expect(pet(born: DateTime(2019, 9, 14)).birthdayIsNear(today), isTrue); // today
      expect(pet(born: null).birthdayIsNear(today), isFalse);
    });
  });

  group('labels', () {
    testWidgets('age reads in the local language, with correct plurals',
        (tester) async {
      Future<String> label(DateTime born) async {
        late String result;
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
            home: Builder(builder: (context) {
              result = petAgeLabel(context, pet(born: born));
              return const SizedBox();
            }),
          ),
        );
        return result;
      }

      // This used to read "7 yr" — the last untranslated string on the
      // pets screen, and one where the plural actually changes the word.
      expect(await label(DateTime(2025, 1, 1)), '1 godina');
      expect(await label(DateTime(2023, 1, 1)), '3 godine');
      expect(await label(DateTime(2019, 1, 1)), '7 godina');
    });

    testWidgets('no badge when the birthday is far off', (tester) async {
      await pumpBadge(tester, pet(born: DateTime(2019, 3, 22)), asOf: today);
      expect(find.byIcon(Icons.cake_rounded), findsNothing);
    });

    testWidgets('a countdown badge in the fortnight before', (tester) async {
      await pumpBadge(tester, pet(born: DateTime(2019, 9, 19)), asOf: today);
      expect(find.text('Rođendan za 5 dana'), findsOneWidget);
    });

    testWidgets('the day itself says so', (tester) async {
      await pumpBadge(tester, pet(born: DateTime(2019, 9, 14)), asOf: today);
      expect(find.text('Rođendan danas!'), findsOneWidget);
    });

    testWidgets('a pet with no birth date never shows a badge', (tester) async {
      await pumpBadge(tester, pet(born: null), asOf: today);
      expect(find.byIcon(Icons.cake_rounded), findsNothing);
    });
  });
}
