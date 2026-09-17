// Pet photographs, which the backend has been sending all along.
//
// Animal.Picture is a byte[] on the entity and base64 on the wire, and
// AnimalGetByOwnerId returns the entity whole — so every response has
// carried the photos and the app read past them, drawing a species
// silhouette instead. Four dogs looked like four copies of one picture
// because that is exactly what they were.
//
// The interesting cases are not the happy one. A photo column written to
// by several versions of an admin panel will contain surprises, and a
// pet list is the wrong place to discover them.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/models/pet.dart';
import 'package:vetnow_mobile/services/pets_api_service.dart';
import 'package:vetnow_mobile/widgets/pet_avatar.dart';

import 'support/fake_backend.dart';

/// A one-pixel PNG, which is the smallest thing Image.memory will accept.
const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(resetBackend);

  group('reading the field', () {
    Pet onlyPet(List<Map<String, dynamic>> rows) =>
        PetsApiService.mapPets(rows, null).single;

    test('a photo comes through', () {
      final pet = onlyPet([
        {'id': 1, 'name': 'Rex', 'picture': _onePixelPng},
      ]);

      expect(pet.photoBase64, _onePixelPng);
    });

    test('no photo is null, not an empty string', () {
      expect(onlyPet([{'id': 1, 'name': 'Rex'}]).photoBase64, isNull);
    });

    test('an empty column is no photo', () {
      // What an unset byte[] serialises to, and not the same thing as a
      // photograph of nothing.
      expect(onlyPet([
        {'id': 1, 'name': 'Rex', 'picture': ''},
      ]).photoBase64, isNull);

      expect(onlyPet([
        {'id': 1, 'name': 'Rex', 'picture': '   '},
      ]).photoBase64, isNull);
    });
  });

  group('drawing it', () {
    testWidgets('a pet with a photo shows the photo', (tester) async {
      await pump(
        tester,
        const PetAvatar(
          species: 'Pas',
          seed: 1,
          name: 'Rex',
          photoBase64: _onePixelPng,
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      // And not the monogram, which exists to stand in for a photo.
      expect(find.text('R'), findsNothing);
    });

    testWidgets('a pet without one falls back to its initial', (tester) async {
      await pump(
        tester,
        const PetAvatar(species: 'Pas', seed: 1, name: 'Rex'),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('a data URI is accepted, not just bare base64',
        (tester) async {
      // Some rows were written by a web admin panel that stores the
      // whole data: URI rather than the payload on its own.
      await pump(
        tester,
        const PetAvatar(
          species: 'Pas',
          seed: 1,
          name: 'Rex',
          photoBase64: 'data:image/png;base64,$_onePixelPng',
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a photo that is not base64 falls back rather than throwing',
        (tester) async {
      await pump(
        tester,
        const PetAvatar(
          species: 'Pas',
          seed: 1,
          name: 'Rex',
          photoBase64: 'this is not an image',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('base64 that is not an image does not become an error glyph',
        (tester) async {
      // Decodes cleanly and then fails to be a picture. One bad row must
      // not turn a row of portraits into a row of broken-image icons.
      await pump(
        tester,
        PetAvatar(
          species: 'Pas',
          seed: 1,
          name: 'Rex',
          photoBase64: base64Encode(utf8.encode('definitely not a png')),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('two pets of the same species still look different',
        (tester) async {
      // The complaint that started this: a row of dogs was a row of one
      // picture. Without a photo the initial has to carry it.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                PetAvatar(species: 'Pas', seed: 1, name: 'Rex'),
                PetAvatar(species: 'Pas', seed: 2, name: 'Bela'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('R'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('a nameless pet still gets a portrait', (tester) async {
      await pump(tester, const PetAvatar(species: 'Macka', seed: 3));

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
