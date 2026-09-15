// The disc that stands in for a person's photo.
//
// Nobody in this system has a photo, so before this every vet, nurse and
// reviewer wore the same grey silhouette on the same gradient. The whole
// point of the widget is that two people look like two people — so that
// is what is tested, along with the naming conventions that would
// otherwise defeat it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/config/theme.dart';
import 'package:vetnow_mobile/widgets/person_avatar.dart';

Future<LinearGradient> gradientOf(WidgetTester tester, String name) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: PersonAvatar(name: name))),
  ));

  final box = tester.widget<Container>(
    find.descendant(of: find.byType(PersonAvatar), matching: find.byType(Container)).first,
  );
  return (box.decoration! as BoxDecoration).gradient! as LinearGradient;
}

String? initialsOf(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text));
  return texts.isEmpty ? null : texts.first.data;
}

Future<void> pumpAvatar(WidgetTester tester, String name, {double size = 52}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: PersonAvatar(name: name, size: size))),
  ));
}

void main() {
  group('initials', () {
    testWidgets('first letters of the first two names', (tester) async {
      await pumpAvatar(tester, 'Amina Hodžić');
      expect(initialsOf(tester), 'AH');
    });

    testWidgets('titles are skipped', (tester) async {
      // Every vet on a clinic page starts with "Dr.". Taking the first
      // two words literally would give half the team "DA", "DE", "DL" —
      // all starting with the same letter, which is the problem this
      // widget exists to solve.
      await pumpAvatar(tester, 'Dr. Amina Hodžić');
      expect(initialsOf(tester), 'AH');

      await pumpAvatar(tester, 'dr Emir Kovač');
      expect(initialsOf(tester), 'EK');
    });

    testWidgets('one name gives one letter', (tester) async {
      await pumpAvatar(tester, 'Lejla');
      expect(initialsOf(tester), 'L');
    });

    testWidgets('local letters are kept as they are', (tester) async {
      await pumpAvatar(tester, 'Željko Ćorić');
      expect(initialsOf(tester), 'ŽĆ');
    });

    testWidgets('a nameless person falls back to the silhouette, not a blank',
        (tester) async {
      await pumpAvatar(tester, '');
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('so does a name with nothing usable in it', (tester) async {
      await pumpAvatar(tester, '   ');
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('colour', () {
    testWidgets('the same person is the same colour every time',
        (tester) async {
      // Keyed on the name rather than an id, because a review carries no
      // id for its author. Stable across launches is the whole point:
      // an avatar that changes colour on every build is worse than one
      // that never varies.
      final first = await gradientOf(tester, 'Amina Hodžić');
      final again = await gradientOf(tester, 'Amina Hodžić');

      expect(first.colors, again.colors);
    });

    testWidgets('a title does not change it', (tester) async {
      // The same person written two ways in two places must not appear
      // as two different people.
      final withTitle = await gradientOf(tester, 'Dr. Amina Hodžić');
      final without = await gradientOf(tester, 'Amina Hodžić');

      expect(withTitle.colors, without.colors);
    });

    testWidgets('neither does casing or stray spacing', (tester) async {
      final plain = await gradientOf(tester, 'Emir Kovač');
      final messy = await gradientOf(tester, '  EMIR KOVAČ ');

      expect(plain.colors, messy.colors);
    });

    testWidgets('a team does not come out in one colour', (tester) async {
      // The actual failure being prevented: three vets that look like
      // one vet listed three times.
      final team = <List<Color>>[];
      for (final name in [
        'Dr. Amina Hodžić',
        'Dr. Emir Kovač',
        'Lejla Begić',
        'Selma Arnaut',
      ]) {
        team.add((await gradientOf(tester, name)).colors);
      }

      expect(team.toSet().length, greaterThan(1));
    });

    testWidgets('an explicit palette wins, for a page built around one',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PersonAvatar(
              name: 'Amir Hadžić',
              colors: [AppColors.accent, AppColors.gold],
            ),
          ),
        ),
      ));

      final box = tester.widget<Container>(
        find.descendant(of: find.byType(PersonAvatar), matching: find.byType(Container)).first,
      );
      final gradient = (box.decoration! as BoxDecoration).gradient! as LinearGradient;

      expect(gradient.colors, [AppColors.accent, AppColors.gold]);
    });
  });

  group('layout', () {
    testWidgets('it is exactly the size it was asked for', (tester) async {
      // It is dropped inside rings and rows that reserve a fixed box; a
      // disc that rounds up its own size overflows them.
      await pumpAvatar(tester, 'Amina Hodžić', size: 86);

      expect(tester.getSize(find.byType(PersonAvatar)), const Size(86, 86));
      expect(tester.takeException(), isNull);
    });

    testWidgets('it stays inside a tighter parent', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: PersonAvatar(name: 'Amina Hodžić', size: 40),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
