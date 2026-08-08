enum AppointmentStatus { upcoming, completed, cancelled }

/// Mirrors VetStat/Models/Appointment.cs (Customer, VetStation, Employee,
/// TimeSlot, Animal) flattened into display-ready fields for the UI.
class Appointment {
  final int id;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;
  final String staffName;
  final String staffRole;
  final String petName;
  final String serviceName;
  final String serviceDescription;
  final double priceKm;
  final int durationMinutes;
  final DateTime dateTime;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicPhone,
    required this.staffName,
    required this.staffRole,
    required this.petName,
    required this.serviceName,
    required this.serviceDescription,
    required this.priceKm,
    required this.durationMinutes,
    required this.dateTime,
    required this.status,
  });
}
