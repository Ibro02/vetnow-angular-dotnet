import '../config/api_config.dart';
import 'api_client.dart';

class RemoteTimeSlot {
  final int id;
  final String appointmentTime; // "hh:mm"
  final DateTime slotDateTime;
  const RemoteTimeSlot({required this.id, required this.appointmentTime, required this.slotDateTime});

  factory RemoteTimeSlot.fromJson(Map<String, dynamic> json) => RemoteTimeSlot(
        id: json['id'] as int,
        appointmentTime: json['appointmentTime'] as String? ?? '',
        slotDateTime: DateTime.parse(json['slotDateTime'] as String),
      );
}

class TimeSlotApiService {
  TimeSlotApiService._();

  /// GET /api/TimeSlot/Get?employeeid=&date=yyyy-MM-dd — [Authorize].
  /// Returns only *available* slots for that single day. The backend
  /// returns 204 No Content (empty body) when there are none, which
  /// ApiClient decodes as null — we treat that the same as an empty list.
  static Future<List<RemoteTimeSlot>> getForEmployee({
    required int employeeId,
    required DateTime date,
    required String token,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = await ApiClient.get(
      ApiConfig.timeSlotGet,
      query: {'employeeid': employeeId, 'date': dateStr},
      token: token,
    );
    if (result == null) return [];
    final list = result as List<dynamic>;
    return list.map((e) => RemoteTimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }
}
