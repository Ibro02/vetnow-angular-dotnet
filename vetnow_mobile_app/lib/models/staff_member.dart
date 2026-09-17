import 'vet_service.dart';

/// A single staff member at a station. Each one can offer a different
/// subset of services with their own duration/price — this is the
/// piece the current backend Availability model doesn't capture yet
/// (AppointmentDuration is one fixed value per employee for the whole
/// day, not per service). Modeling it here now so the UI is ready for
/// when that becomes a real per-service field on the backend.
class StaffMember {
  final int id;
  final String name;
  final String role; // Veterinarian, Nurse, Groomer, Main Vet
  final String bio;
  final double rating;
  final int reviewCount;
  final List<VetService> services;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.services = const [],
  });
}
