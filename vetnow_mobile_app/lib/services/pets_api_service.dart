import 'dart:async';

import '../config/api_config.dart';
import '../models/pet.dart';
import 'account_cache.dart';
import 'api_client.dart';
import 'json_list.dart';

class PetsApiService {
  PetsApiService._();

  /// GET /api/Animal/GetByOwnerId?id= — [Authorize]. Fine since Pets
  /// screens already sit behind our login gate.
  static Future<List<Pet>> getByOwner({required int ownerId, required String token, Map<int, String>? speciesNames}) async {
    final raw = await getByOwnerRaw(ownerId: ownerId, token: token);
    return mapPets(raw, speciesNames);
  }

  /// Same request, but returns the untouched JSON.
  ///
  /// Species names are only needed to *map* the response, never to make
  /// it — so callers that also fetch the species list can fire both at
  /// once and join them afterwards, instead of waiting for species first.
  static Future<List<Map<String, dynamic>>> getByOwnerRaw({
    required int ownerId,
    required String token,
  }) async {
    final result = await ApiClient.get(
      ApiConfig.animalByOwner,
      query: {'id': ownerId},
      token: token,
    );
    final list = result as List<dynamic>? ?? [];
    final rows = list.whereType<Map<String, dynamic>>().toList();

    // Kept for a launch without a connection. Not awaited: the caller
    // is waiting to render, and writing a cache is housekeeping that
    // must not add to that wait.
    unawaited(AccountCache.save('pets', ownerId, rows));

    return rows;
  }

  /// The last rows this account saw, for when the request fails.
  ///
  /// Raw rather than mapped, because the names for species and breed
  /// are fetched separately — the caller joins them with whatever it
  /// has, which offline is usually nothing, and a pet with a blank
  /// species still beats an error page.
  static Future<List<Map<String, dynamic>>?> cachedFor(int ownerId) =>
      AccountCache.read('pets', ownerId);

  static List<Pet> mapPets(
    List<Map<String, dynamic>> raw,
    Map<int, String>? speciesNames, {
    Map<int, String>? breedNames,
  }) =>
      parseRows(
        raw,
        (row) => _petFromAnimalJson(row, speciesNames, breedNames),
        context: 'pets',
      );

  /// Which species the rows mention, for fetching their breeds.
  static Set<int> speciesIdsIn(List<Map<String, dynamic>> raw) => {
        for (final row in raw)
          if (row['animalSpeciesId'] is int) row['animalSpeciesId'] as int,
      };

  static Pet _petFromAnimalJson(
    Map<String, dynamic> json,
    Map<int, String>? speciesNames,
    Map<int, String>? breedNames,
  ) {
    final speciesId = json['animalSpeciesId'] as int?;
    final breedId = json['breedId'] as int?;
    return Pet(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      species: speciesId != null ? (speciesNames?[speciesId] ?? '') : '',
      speciesId: speciesId,
      // The entity carries only a breedId, so the name has to be
      // joined on the device. Blank when nobody looked it up, which is
      // every caller that has no reason to — the detail screen shows a
      // dash for it and the list does not show it at all.
      breed: breedId != null ? (breedNames?[breedId] ?? '') : '',
      breedId: breedId,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      isFavourite: json['isFavourite'] as bool? ?? false,
      // byte[] on the entity, base64 on the wire. Blank strings are
      // treated as no photo, which is what an empty column serialises
      // to and is not the same thing as a photo of nothing.
      photoBase64: (json['picture'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['picture'] as String?,
    );
  }

  /// POST /api/PetsUpdateOrInsert/Save — [Authorize]. Pass id: null (or
  /// omit) to insert a new pet; pass an existing id to update it.
  /// Also used to toggle isFavourite alone (pass just id + isFavourite).
  static Future<int> save({
    required String token,
    int? id,
    String? name,
    DateTime? birthDate,
    int? animalSpeciesId,
    int? breedId,
    bool? isFavourite,
  }) async {
    final result = await ApiClient.post(
      ApiConfig.petsSave,
      token: token,
      body: {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (animalSpeciesId != null) 'animalSpeciesId': animalSpeciesId,
        if (breedId != null) 'breedId': breedId,
        if (isFavourite != null) 'isFavourite': isFavourite,
      },
    );
    return result as int;
  }

  /// DELETE /api/Pets/SoftDelete?id= — [Authorize].
  static Future<void> delete({required int id, required String token}) async {
    await ApiClient.delete(ApiConfig.petsSoftDelete, query: {'id': id}, token: token);
  }
}
