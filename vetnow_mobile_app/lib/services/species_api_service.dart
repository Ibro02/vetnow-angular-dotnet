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
    return _cached ??= _fetch().catchError((Object error, StackTrace stack) {
      // Never cache a failure — a network hiccup would otherwise poison
      // the list for the whole session.
      _cached = null;
      // throwWithStackTrace rather than `throw error`: a bare rethrow
      // from inside catchError replaces the stack with this line, so
      // every species failure looked like it started here instead of
      // wherever the request actually failed.
      Error.throwWithStackTrace(error, stack);
    });
  }

  /// Drops the cache. Call after the catalogue itself could have changed
  /// (an admin adding a species), not on ordinary navigation.
  static void invalidate() => _cached = null;

  static Future<List<SpeciesOption>> _fetch() async {
    final result = await ApiClient.get(ApiConfig.speciesGetAll, query: {'pageSize': 100});

    // Every read below is defensive on purpose. This decodes whatever
    // the server sent, and the previous version asserted the shape
    // with casts: an envelope that was not a map, an id that arrived
    // as a string, or one malformed row in an otherwise good list
    // each threw a TypeError with nothing in it about species — and
    // took out the whole picker rather than one entry in it.
    final envelope = result is Map<String, dynamic> ? result : const {};
    final items = envelope['dataItems'];
    if (items is! List) return const [];

    final options = <SpeciesOption>[];
    for (final item in items) {
      if (item is! Map) continue;

      // The backend sends an int; a stringly-typed one still works.
      final id = _asInt(item['id']);
      if (id == null) continue;

      // Backend field is SpeciesName -> speciesName in camelCase JSON.
      final name = item['speciesName'] ?? item['name'];
      options.add(SpeciesOption(
        id: id,
        name: name is String && name.trim().isNotEmpty ? name : 'Unknown',
      ));
    }
    return options;
  }

  static int? _asInt(Object? value) => switch (value) {
        final int v => v,
        final num v => v.toInt(),
        final String v => int.tryParse(v),
        _ => null,
      };
}
