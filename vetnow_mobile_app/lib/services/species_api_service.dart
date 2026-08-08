import '../config/api_config.dart';
import 'api_client.dart';

class SpeciesOption {
  final int id;
  final String name;
  const SpeciesOption({required this.id, required this.name});
}

class SpeciesApiService {
  SpeciesApiService._();

  /// GET /api/SpeciesGetAll/Get — AllowAnonymous. Paginated envelope
  /// ({ totalCount, dataItems, currentPage, pageSize }); dataItems are
  /// raw Species entities. We only need id + name for the picker.
  static Future<List<SpeciesOption>> getAll() async {
    final result = await ApiClient.get(ApiConfig.speciesGetAll, query: {'pageSize': 100});
    final items = (result as Map<String, dynamic>)['dataItems'] as List<dynamic>? ?? [];
    return items
        .map((e) => SpeciesOption(
              id: e['id'] as int,
              // Backend field is SpeciesName -> speciesName in camelCase JSON.
              name: (e['speciesName'] ?? e['name'] ?? 'Unknown') as String,
            ))
        .toList();
  }
}
