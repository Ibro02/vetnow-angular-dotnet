import '../models/vet_service.dart';
import 'employee_api_service.dart';

/// Who is allowed to perform which service.
///
/// The booking screen used to offer the station's whole team for every
/// service, so a groomer could be picked for a dental procedure and a
/// vet for a nail trim. Neither is a thing that happens in a real clinic,
/// and the first person to notice would be the clinic.
///
/// This is a mapping by trade, not by person, and the distinction is
/// worth being honest about. The backend models employees as real
/// subtypes — Vet, Nurse, Barber — and has an endpoint per trade, which
/// is what makes this possible at all. What it does not have is any
/// record of which *individual* performs which service. "Dr. Emir does
/// dentistry but not vaccinations" is not expressible until there is a
/// table for it, and that table would be a backend change.
///
/// So: a trade-level filter, which is correct as far as it goes and
/// removes every nonsensical pairing, rather than a person-level one
/// that would need data nobody has yet.
class ServiceStaffing {
  ServiceStaffing._();

  /// The endpoint to ask for a given service.
  ///
  /// Grooming is the clear-cut one: it is the groomer's trade and nobody
  /// else's. Vaccination admits nurses, who give injections in every
  /// clinic there is. Examinations and dentistry are a vet's work.
  ///
  /// A service with no kind — anything coming from a future backend
  /// catalogue rather than from this app's four — falls through to the
  /// whole team rather than to nobody. Showing everyone is a poor
  /// filter; showing no one is a dead end.
  static StaffRoleFilter filterFor(ServiceKind? kind) => switch (kind) {
        ServiceKind.grooming => StaffRoleFilter.groomers,
        ServiceKind.vaccination => StaffRoleFilter.vetsAndNurses,
        ServiceKind.checkup => StaffRoleFilter.vets,
        ServiceKind.dental => StaffRoleFilter.vets,
        null => StaffRoleFilter.all,
      };
}
