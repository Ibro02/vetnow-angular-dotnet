import '../config/api_config.dart';
import '../models/pet.dart';
import 'api_client.dart';

class PetsApiService {
  PetsApiService._();

  /// GET /api/Animal/GetByOwnerId?id= — [Authorize]. Fine since Pets
  /// screens already sit behind our login gate.
  static Future<List<Pet>> getByOwner({required int ownerId, required String token, Map<int, String>? speciesNames}) async {
    final result = await ApiClient.get(
      ApiConfig.animalByOwner,
      query: {'id': ownerId},
      token: token,
    );
    final list = result as List<dynamic>? ?? [];
    return list.map((e) => _petFromAnimalJson(e as Map<String, dynamic>, speciesNames)).toList();
  }

  static Pet _petFromAnimalJson(Map<String, dynamic> json, Map<int, String>? speciesNames) {
    final speciesId = json['animalSpeciesId'] as int?;
    return Pet(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      species: speciesId != null ? (speciesNames?[speciesId] ?? '') : '',
      // Breed name isn't included on the Animal entity itself (only
      // breedId) — showing blank here until we also fetch/join Breed.
      breed: '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
    );
  }

  /// POST /api/PetsUpdateOrInsert/Save — [Authorize]. Pass id: null (or
  /// omit) to insert a new pet; pass an existing id to update it.
  static Future<int> save({
    required String token,
    int? id,
    String? name,
    DateTime? birthDate,
    int? animalSpeciesId,
    int? breedId,
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
      },
    );
    return result as int;
  }

  /// DELETE /api/Pets/SoftDelete?id= — [Authorize].
  static Future<void> delete({required int id, required String token}) async {
    await ApiClient.delete(ApiConfig.petsSoftDelete, query: {'id': id}, token: token);
  }
}
