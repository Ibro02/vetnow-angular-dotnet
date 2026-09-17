import '../config/api_config.dart';
import 'api_client.dart';

/// Breed names, which the pet detail screen has been showing as a dash.
///
/// Animal carries a BreedId and the response has always included it;
/// nothing resolved it to a name, so "Pasmina" read "—" on every pet in
/// the app. ApiConfig has had the endpoint listed since the beginning
/// with no caller.
///
/// Breeds are filed under a species, so there is no "all breeds" call to
/// make. The lookup takes the species actually present and asks about
/// those, which for a normal owner is one request, or two if they keep
/// both a dog and a cat.
class BreedApiService {
  BreedApiService._();

  /// Per species, for the rest of the session.
  ///
  /// Reference data that does not change while the app is open, and the
  /// pets list, the profile and the pet page all want the same answer.
  /// The Future is cached rather than the result, so two screens asking
  /// at the same moment collapse into one request.
  static final Map<int, Future<Map<int, String>>> _bySpecies = {};

  /// Breed id to name for every species in [speciesIds], merged.
  ///
  /// A species whose lookup fails is left out rather than failing the
  /// whole map: a missing breed name is a dash on one row, and that is a
  /// much smaller thing than a pet list that will not load.
  static Future<Map<int, String>> namesFor(
    Iterable<int> speciesIds, {
    required String token,
  }) async {
    final wanted = speciesIds.toSet();
    if (wanted.isEmpty) return const {};

    final results = await Future.wait(
      wanted.map((id) => _forSpecies(id, token).catchError((_) => <int, String>{})),
    );

    return {for (final map in results) ...map};
  }

  static Future<Map<int, String>> _forSpecies(int speciesId, String token) {
    return _bySpecies[speciesId] ??= _fetch(speciesId, token).catchError(
      (Object error, StackTrace stack) {
        // Never cache a failure; a hiccup would otherwise leave this
        // species without breed names for the whole session.
        _bySpecies.remove(speciesId);
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  /// GET /api/BreedGetBySpecies/Get?speciesId= — the same paginated
  /// envelope the species list uses.
  static Future<Map<int, String>> _fetch(int speciesId, String token) async {
    final result = await ApiClient.get(
      ApiConfig.breedBySpecies,
      query: {'speciesId': speciesId},
      token: token,
    );

    final items = (result as Map<String, dynamic>)['dataItems'] as List<dynamic>? ?? [];
    return {
      for (final row in items.whereType<Map<String, dynamic>>())
        if (row['id'] is int && row['name'] is String) row['id'] as int: row['name'] as String,
    };
  }

  /// Drops every cached lookup. For when the catalogue itself could have
  /// changed, not on ordinary navigation.
  static void invalidate() => _bySpecies.clear();
}
