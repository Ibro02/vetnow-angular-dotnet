import 'dart:async';

import '../config/api_config.dart';
import '../models/opening_hours.dart';
import '../models/vet_station.dart';
import 'api_client.dart';
import 'json_list.dart';
import 'clinic_cache.dart';

class VetStationApiService {
  VetStationApiService._();

  /// GET /api/VetStationSearch — AllowAnonymous, matches the guest-first
  /// browsing model. Optional [name] filters server-side; amenity
  /// filters (parking/wifi/etc.) exist on the backend too but aren't
  /// wired here yet since Explore currently filters by rating/distance
  /// client-side (fields the backend doesn't have — see chat notes).
  static Future<List<VetStation>> search({String? name}) async {
    final result = await ApiClient.get(
      ApiConfig.vetStationSearch,
      query: {if (name != null && name.trim().isNotEmpty) 'name': name.trim()},
    );
    // The envelope is still asserted, and still throws when it is wrong.
    // A response that is not the shape of an answer means we did not get
    // one, and "0 clinics found" would be a lie about it  14 the screen
    // has an error state and a retry button for exactly this case. Only
    // the rows inside a good envelope are forgiving.
    final list = (result as Map<String, dynamic>)['vetStations'] as List<dynamic>? ?? [];
    final raw = list.whereType<Map<String, dynamic>>().toList();

    // Only an unfiltered list is worth keeping: it is what Explore opens
    // with. Caching a search for "Ferhadija" would mean the next launch
    // starts on someone's old query.
    if (name == null || name.trim().isEmpty) {
      // Deliberately not awaited — the caller is waiting to render, and
      // writing the cache is housekeeping that must not add to that wait.
      unawaited(ClinicCache.save(raw));
    }

    // Row by row rather than list.map: one clinic with a null id used
    // to throw out of the whole request, and Explore showed a
    // connection error over the nine clinics that were fine.
    return parseRows(raw, VetStation.fromJson, context: 'clinics');
  }

  /// GET /api/VetStation/OpeningHours?vetStationId= — AllowAnonymous.
  ///
  /// The hours are derived server-side from the staff schedules already in
  /// the database, so "open now" is decided against the server's clock
  /// rather than the phone's.
  static Future<OpeningHours> openingHours(int vetStationId) async {
    final result = await ApiClient.get(
      ApiConfig.vetStationOpeningHours,
      query: {'vetStationId': vetStationId},
    );
    return OpeningHours.fromJson(result as Map<String, dynamic>);
  }

  /// GET /api/VetStation/Get?id= — AllowAnonymous.
  static Future<VetStation?> getById(int id) async {
    final result = await ApiClient.get(ApiConfig.vetStationGetById, query: {'id': id});
    final list = result as List<dynamic>?;
    if (list == null || list.isEmpty) return null;
    return VetStation.fromJson(list.first as Map<String, dynamic>);
  }
}
