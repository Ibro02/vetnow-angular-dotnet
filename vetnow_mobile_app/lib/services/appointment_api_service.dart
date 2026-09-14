import '../config/api_config.dart';
import 'api_client.dart';

/// Flattened shape returned by GET /api/Appointment/GetByCustomerId —
/// mirrors AppointmentGetByCustomerIdEndpoint's anonymous projection
/// exactly (it's a joined view, not the raw Appointment entity).
///
/// Past visits come back too when `includePast` is set; without it the
/// endpoint returns only what is still ahead, which is what the web
/// dashboard expects.
class RemoteAppointment {
  final int id;
  final int employeeId;
  final int vetStationId;
  final int animalId;
  final int timeSlotId;
  final DateTime slotDateTime;
  final String appointmentTime;
  final String? animalName;
  final String? speciesName;
  final String? employeeFirstName;
  final String? employeeLastName;
  final String? vetStationName;

  const RemoteAppointment({
    required this.id,
    required this.employeeId,
    required this.vetStationId,
    required this.animalId,
    required this.timeSlotId,
    required this.slotDateTime,
    required this.appointmentTime,
    this.animalName,
    this.speciesName,
    this.employeeFirstName,
    this.employeeLastName,
    this.vetStationName,
  });

  factory RemoteAppointment.fromJson(Map<String, dynamic> json) => RemoteAppointment(
        id: json['id'] as int,
        employeeId: json['employeeId'] as int,
        vetStationId: json['vetStationId'] as int,
        animalId: json['animalId'] as int,
        timeSlotId: json['timeSlotId'] as int,
        slotDateTime: DateTime.parse(json['slotDateTime'] as String),
        appointmentTime: json['appointmentTime'] as String? ?? '',
        animalName: json['animalName'] as String?,
        speciesName: json['speciesName'] as String?,
        employeeFirstName: json['employeeFirstName'] as String?,
        employeeLastName: json['employeeLastName'] as String?,
        vetStationName: json['vetStationName'] as String?,
      );
}

class AppointmentApiService {
  AppointmentApiService._();

  /// [includePast] also returns visits that already happened, so the screen
  /// can fill its "past visits" tab from the same single request.
  static Future<List<RemoteAppointment>> getByCustomer({
    required int customerId,
    required String token,
    bool includePast = false,
  }) async {
    final result = await ApiClient.get(
      ApiConfig.appointmentByCustomer,
      query: {
        'customerId': customerId,
        if (includePast) 'includePast': true,
      },
      token: token,
    );
    final list = result as List<dynamic>? ?? [];
    return list.map((e) => RemoteAppointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/Appointment/Add — [Authorize]. CustomerId is set
  /// server-side from the token, so we don't send it. The backend
  /// validates the animal belongs to the caller and the slot is still
  /// free, so a 409/400 here is a real, user-facing conflict (e.g. slot
  /// just got taken) — not a bug.
  static Future<void> add({
    required int animalId,
    required int timeSlotId,
    required int employeeId,
    required int vetStationId,
    required String token,
  }) async {
    await ApiClient.post(
      ApiConfig.appointmentAdd,
      token: token,
      body: {
        'animalId': animalId,
        'timeSlotId': timeSlotId,
        'employeeId': employeeId,
        'vetStationId': vetStationId,
      },
    );
  }

  /// DELETE /api/Appointment/Cancel?appointmentId= — [Authorize].
  static Future<void> cancel({required int appointmentId, required String token}) async {
    await ApiClient.delete(ApiConfig.appointmentCancel, query: {'appointmentId': appointmentId}, token: token);
  }

  /// PUT /api/Appointment/Reschedule — [Authorize].
  ///
  /// The backend only accepts a slot that belongs to the SAME employee as
  /// the original appointment, and refuses one that is already taken. It
  /// frees the old slot and books the new one in a single operation, so
  /// there is no window where the person holds two slots or none.
  ///
  /// A 409 here is a real conflict the user should see (someone booked
  /// that slot first), not a bug.
  static Future<void> reschedule({
    required int appointmentId,
    required int newTimeSlotId,
    required String token,
  }) async {
    await ApiClient.put(
      ApiConfig.appointmentReschedule,
      token: token,
      body: {
        'appointmentId': appointmentId,
        'newTimeSlotId': newTimeSlotId,
      },
    );
  }
}
