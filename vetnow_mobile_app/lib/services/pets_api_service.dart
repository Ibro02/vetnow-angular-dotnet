import '../config/api_config.dart';
import '../models/pet.dart';
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
    return list.cast<Map<String, dynamic>>();
  }

  static List<Pet> mapPets(List<Map<String, dynamic>> raw, Map<int, String>? speciesNames) =>
      parseRows(
        raw,
        (row) => _petFromAnimalJson(row, speciesNames),
        context: 'pets',
      );

  static Pet _petFromAnimalJson(Map<String, dynamic> json, Map<int, String>? speciesNames) {
    final speciesId = json['animalSpeciesId'] as int?;
    return Pet(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      species: speciesId != null ? (speciesNames?[speciesId] ?? '') : '',
      speciesId: speciesId,
      // Breed name isn't included on the Animal entity itself (only
      // breedId) — showing blank here until we also fetch/join Breed.
      breed: '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      isFavourite: json['isFavourite'] as bool? ?? false,
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
