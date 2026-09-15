// Pet portraits: the species mapping, and a golden of the six shapes.
//
// The golden is the point of this file. The silhouettes are drawn with a
// CustomPainter, so nothing but a rendered image can tell you whether a
// cat still looks like a cat — `flutter test --update-goldens` writes
// test/goldens/pet_silhouettes.png, and any later change to the geometry
// has to be looked at and accepted deliberately.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/widgets/pet_avatar.dart';

void main() {
  group('species mapping', () {
    test('recognises the species the backend actually ships', () {
      expect(petKindFor('Dog'), PetKind.dog);
      expect(petKindFor('Cat'), PetKind.cat);
      expect(petKindFor('Rabbit'), PetKind.rabbit);
      expect(petKindFor('Turtle'), PetKind.turtle);
      expect(petKindFor('Goldfish'), PetKind.fish);
      expect(petKindFor('Budgerigar'), PetKind.bird);
      expect(petKindFor('Parrot'), PetKind.bird);
    });

    test('small mammals share the rabbit silhouette', () {
      // A hamster and a guinea pig are indistinguishable at 40 pixels;
      // giving them separate shapes would make both of them worse.
      expect(petKindFor('Hamster'), PetKind.rabbit);
      expect(petKindFor('Guinea Pig'), PetKind.rabbit);
      expect(petKindFor('Ferret'), PetKind.rabbit);
    });

    test('matching is case-insensitive and accepts local names', () {
      expect(petKindFor('MAČKA'), PetKind.cat);
      expect(petKindFor('zec'), PetKind.rabbit);
      expect(petKindFor('kornjača'), PetKind.turtle);
      expect(petKindFor('ptica'), PetKind.bird);
    });

    test('an unknown species still gets a portrait, never a blank', () {
      // Species is free text a clinic admin types, so this will happen.
      expect(petKindFor('Axolotl'), PetKind.dog);
      expect(petKindFor(''), PetKind.dog);
    });
  });

  group('PetAvatar', () {
    testWidgets('the same pet always gets the same colours', (tester) async {
      // Read the gradient off the rendered tree rather than off build()'s
      // return value: the wrappers around the painted box (the clip, the
      // semantics exclusion) are presentation and change more often than
      // the thing actually under test.
      Future<Gradient> gradientOf(int seed) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: Center(child: PetAvatar(species: 'Dog', seed: seed))),
        ));
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(PetAvatar),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).gradient!;
      }

      final three = (await gradientOf(3)) as LinearGradient;
      final threeAgain = (await gradientOf(3)) as LinearGradient;
      final four = (await gradientOf(4)) as LinearGradient;

      expect(three.colors, threeAgain.colors);
      expect(four.colors, isNot(three.colors));
    });

    testWidgets('renders at a list row size without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: PetAvatar(species: 'Cat', seed: 1, size: 36))),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('expand mode fills its parent instead of a fixed circle',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, height: 120, child: PetAvatar(species: 'Dog', seed: 1, expand: true)),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(ClipOval), findsNothing);
    });

    testWidgets('the six silhouettes look like themselves', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFFAF9F6),
            body: Center(
              child: RepaintBoundary(
                child: SizedBox(
                  width: 760,
                  height: 220,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final species in ['Dog', 'Cat', 'Rabbit', 'Parrot', 'Goldfish', 'Turtle'])
                        PetAvatar(species: species, seed: 0, size: 112),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/pet_silhouettes.png'),
      );
    });
  });
}
