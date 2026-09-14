import '../config/api_config.dart';
import 'api_client.dart';

class SpeciesOption {
  final int id;
  final String name;
  const SpeciesOption({required this.id, required this.name});
}

class SpeciesApiService {
  SpeciesApiService._();

  /// In-flight or completed request, reused for the rest of the session.
  ///
  /// The species list is reference data that does not change while the
  /// app is open, yet three screens ask for it (pets, profile, add-pet)
  /// and pets/profile block on it before they can even request the pets.
  /// Caching the Future — not just the result — also collapses two
  /// screens asking at the same moment into a single request.
  static Future<List<SpeciesOption>>? _cached;

  /// GET /api/SpeciesGetAll/Get — AllowAnonymous. Paginated envelope
  /// ({ totalCount, dataItems, currentPage, pageSize }); dataItems are
  /// raw Species entities. We only need id + name for the picker.
  static Future<List<SpeciesOption>> getAll() {
    return _cached ??= _fetch().catchError((Object e) {
      // Never cache a failure — a network hiccup would otherwise poison
      // the list for the whole session.
      _cached = null;
      throw e;
    });
  }

  /// Drops the cache. Call after the catalogue itself could have changed
  /// (an admin adding a species), not on ordinary navigation.
  static void invalidate() => _cached = null;

  static Future<List<SpeciesOption>> _fetch() async {
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
