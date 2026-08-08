import '../config/api_config.dart';
import '../models/vet_station.dart';
import 'api_client.dart';

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
    final list = (result as Map<String, dynamic>)['vetStations'] as List<dynamic>? ?? [];
    return list.map((e) => VetStation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/VetStation/Get?id= — AllowAnonymous.
  static Future<VetStation?> getById(int id) async {
    final result = await ApiClient.get(ApiConfig.vetStationGetById, query: {'id': id});
    final list = result as List<dynamic>?;
    if (list == null || list.isEmpty) return null;
    return VetStation.fromJson(list.first as Map<String, dynamic>);
  }
}
