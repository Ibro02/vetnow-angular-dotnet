// Breed names, which the pet page has been showing as a dash.
//
// Animal carries a BreedId and the response has always included it.
// Nothing resolved it to a name, so "Pasmina" read "—" on every pet in
// the app, and ApiConfig has listed the endpoint since the beginning
// with no caller.
//
// Breeds are filed under a species, so the lookup is per species. That
// shape is what most of these cases are about: how many requests it
// makes, and what happens when one of them fails.

import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/pets_api_service.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(BreedApiService.invalidate);
  tearDown(() {
    resetBackend();
    BreedApiService.invalidate();
  });

  /// The paginated envelope the breed endpoint answers with.
  Map<String, dynamic> breeds(List<(int, String)> rows) => {
        'dataItems': [
          for (final (id, name) in rows) {'id': id, 'name': name},
        ],
      };

  late FakeBackend backend;

  FakeBackend withBreeds() {
    backend = FakeBackend({
      'BreedGetBySpecies': (r) {
        final speciesId = int.tryParse(r.url.queryParameters['speciesId'] ?? '');
        return switch (speciesId) {
          1 => breeds([(10, 'Njemački ovčar'), (11, 'Mops')]),
          2 => breeds([(20, 'Perzijska mačka')]),
          _ => breeds([]),
        };
      },
    });
    useBackend(backend);
    return backend;
  }

  int breedCalls() =>
      backend.calls.where((c) => c.url.path.contains('BreedGetBySpecies')).length;

  group('namesFor', () {
    test('asks once per species and merges the answers', () async {
      withBreeds();

      final names = await BreedApiService.namesFor({1, 2}, token: 't');

      expect(names[10], 'Njemački ovčar');
      expect(names[20], 'Perzijska mačka');
      expect(breedCalls(), 2);
    });

    test('asks nothing at all when there are no species', () async {
      withBreeds();

      expect(await BreedApiService.namesFor(const {}, token: 't'), isEmpty);
      expect(breedCalls(), 0);
    });

    test('three pets of one species is still one request', () async {
      // The reason the cache is per species rather than per pet: an
      // owner with five dogs should cost one lookup, not five. A List
      // rather than a set literal, since the repetition is the point.
      withBreeds();

      await BreedApiService.namesFor([1, 1, 1], token: 't');

      expect(breedCalls(), 1);
    });

    test('a second screen asking costs nothing', () async {
      withBreeds();

      await BreedApiService.namesFor({1}, token: 't');
      await BreedApiService.namesFor({1}, token: 't');

      expect(breedCalls(), 1);
    });

    test('a species that fails is left out, not fatal', () async {
      // A missing breed name is a dash on one row. A pet list that will
      // not load is a different order of problem, and the second must
      // not be caused by the first.
      withBreeds();
      backend.broken.add('BreedGetBySpecies');

      final names = await BreedApiService.namesFor({1, 2}, token: 't');

      expect(names, isEmpty);
    });

    test('a failure is not cached', () async {
      // Otherwise one hiccup leaves that species without breed names for
      // the rest of the session.
      withBreeds();
      backend.broken.add('BreedGetBySpecies');
      await BreedApiService.namesFor({1}, token: 't');

      backend.broken.clear();
      final names = await BreedApiService.namesFor({1}, token: 't');

      expect(names[10], 'Njemački ovčar');
    });
  });

  group('mapping it onto a pet', () {
    List<Map<String, dynamic>> rows() => [
          {'id': 1, 'name': 'Rex', 'animalSpeciesId': 1, 'breedId': 10},
          {'id': 2, 'name': 'Mica', 'animalSpeciesId': 2, 'breedId': 20},
          {'id': 3, 'name': 'Bez', 'animalSpeciesId': 1},
        ];

    test('speciesIdsIn reports what needs looking up', () {
      expect(PetsApiService.speciesIdsIn(rows()), {1, 2});
    });

    test('a pet with a known breed gets its name', () {
      final pets = PetsApiService.mapPets(
        rows(),
        {1: 'Pas', 2: 'Mačka'},
        breedNames: {10: 'Njemački ovčar', 20: 'Perzijska mačka'},
      );

      expect(pets[0].breed, 'Njemački ovčar');
      expect(pets[0].breedId, 10);
    });

    test('a pet with no breed recorded stays blank', () {
      final pets = PetsApiService.mapPets(rows(), null, breedNames: {10: 'X'});

      expect(pets[2].breed, isEmpty);
      expect(pets[2].breedId, isNull);
    });

    test('a breed id with no name resolves to blank rather than to the id',
        () {
      // Which is what the detail screen renders as a dash. Showing "10"
      // would be worse than showing nothing.
      final pets = PetsApiService.mapPets(rows(), null, breedNames: const {});

      expect(pets[0].breed, isEmpty);
      expect(pets[0].breedId, 10);
    });

    test('callers that pass no breed map at all still work', () {
      // Notifications maps pets purely to count them and has no reason
      // to spend a request on breeds.
      final pets = PetsApiService.mapPets(rows(), null);

      expect(pets, hasLength(3));
      expect(pets.every((p) => p.breed.isEmpty), isTrue);
    });
  });
}
