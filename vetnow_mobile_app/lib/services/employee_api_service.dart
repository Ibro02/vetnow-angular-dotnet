import 'package:flutter/material.dart';
import '../l10n/service_catalog.dart';
import '../models/staff_member.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Which kind of staff to ask the backend for.
///
/// The backend models these as real TPT subtypes (Vet / Nurse / Barber),
/// each with its own endpoint, so filtering happens in SQL rather than by
/// pulling the whole team and sifting through RoleId on the phone.
enum StaffRoleFilter {
  all,
  vets,
  nurses,
  groomers,

  /// Both, merged. There is no single endpoint for it — vaccination
  /// is given by vets and by nurses, and the backend keeps them as
  /// separate subtypes, so this is the one filter that costs two
  /// requests instead of one.
  vetsAndNurses,
}

class EmployeeApiService {
  EmployeeApiService._();

  /// GET the station's staff, optionally narrowed to one role.
  ///
  /// All four endpoints answer with the same paginated envelope and the
  /// same employee DTO, so one parser covers them.
  static Future<List<StaffMember>> getByStationFiltered({
    required int stationId,
    required String token,
    required BuildContext context,
    StaffRoleFilter filter = StaffRoleFilter.all,
  }) async {
    if (filter == StaffRoleFilter.vetsAndNurses) {
      // Fired together rather than one after the other: they are
      // unrelated lookups and waiting for the first to finish before
      // starting the second would double the wait for nothing.
      final both = await Future.wait([
        _fetch(ApiConfig.employeeVetsByStation, stationId, token),
        _fetch(ApiConfig.employeeNursesByStation, stationId, token),
      ]);
      if (!context.mounted) return [];

      // By id, because an employee who is somehow in both lists
      // should appear once.
      final byId = <int, Map<String, dynamic>>{};
      for (final row in [...both[0], ...both[1]]) {
        final id = row['id'];
        if (id is int) byId[id] = row;
      }
      return byId.values.map((e) => _fromJson(e, context)).toList();
    }

    final path = switch (filter) {
      StaffRoleFilter.vets => ApiConfig.employeeVetsByStation,
      StaffRoleFilter.nurses => ApiConfig.employeeNursesByStation,
      StaffRoleFilter.groomers => ApiConfig.employeeBarbersByStation,
      _ => ApiConfig.employeeByStation,
    };

    final items = await _fetch(path, stationId, token);
    if (!context.mounted) return [];
    return items.map((e) => _fromJson(e, context)).toList();
  }

  /// GET /api/Employee/GetByVetStationId?id= — [Authorize]. Real staff
  /// for a station. Role name is derived from RoleId using the fixed
  /// seed order in SeedData/RoleSeeder.cs (1=User, 2=Barber, 3=Nurse,
  /// 4=Vet, 5=MainVet, 6=Admin) since the DTO only returns the id, not
  /// a name — resolved through the same ServiceCatalog role labels the
  /// mock staff already use, so real and mock look consistent.
  ///
  /// Bio/rating/services aren't in the backend at all, so they stay
  /// empty/zero on real employees — StaffProfileScreen already handles
  /// that gracefully ("No services listed yet").
  static Future<List<StaffMember>> getByStation({
    required int stationId,
    required String token,
    required BuildContext context,
  }) async {
    final result = await ApiClient.get(
      ApiConfig.employeeByStation,
      query: {'id': stationId},
      token: token,
    );
    final items = (result as Map<String, dynamic>)['dataItems'] as List<dynamic>? ?? [];
    return items.map((e) => _fromJson(e as Map<String, dynamic>, context)).toList();
  }

  /// The paginated envelope all four endpoints answer with.
  static Future<List<Map<String, dynamic>>> _fetch(
      String path, int stationId, String token) async {
    final result = await ApiClient.get(path, query: {'id': stationId}, token: token);
    final items = (result as Map<String, dynamic>)['dataItems'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  static StaffMember _fromJson(Map<String, dynamic> json, BuildContext context) {
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    final roleId = json['roleId'] as int?;
    return StaffMember(
      id: json['id'] as int,
      name: '$first $last'.trim(),
      role: _roleName(roleId, context),
    );
  }

  static String _roleName(int? roleId, BuildContext context) {
    switch (roleId) {
      case 2:
        return ServiceCatalog.roleGroomer(context);
      case 3:
        return ServiceCatalog.roleNurse(context);
      case 4:
      case 5:
        return ServiceCatalog.roleVeterinarian(context);
      default:
        return '';
    }
  }
}
