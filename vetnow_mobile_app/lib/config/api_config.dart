// ═══════════════════════════════════════════════════════════
// API configuration — points the Flutter app at the VetStat
// ASP.NET Core backend (see VetStat/Properties/launchSettings.json).
// Routes below are copied exactly from the FastEndpoints classes in
// VetStat/Endpoints/**, verified against the actual [Route]/[Http*]
// attributes — not guessed.
// ═══════════════════════════════════════════════════════════

class ApiConfig {
  ApiConfig._();

  /// Base URL of the VetStat backend.
  ///
  /// - Android emulator -> host machine's localhost is 10.0.2.2
  /// - Chrome / web / Windows desktop -> localhost works directly
  /// - Physical device -> use your PC's LAN IP, e.g. http://192.168.1.23:5157
  ///
  /// The backend's dev launch profile listens on:
  ///   https://localhost:7178  (HTTPS)
  ///   http://localhost:5157   (HTTP)
  /// (see VetStat/Properties/launchSettings.json)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5157',
  );

  /// Header name the backend expects for the auth token
  /// (see AuthService.IsLogged() legacy header fallback).
  static const String authHeaderName = 'my-auth-token';

  // ─── Auth ───────────────────────────────────────────────
  static const String login = '/api/LoginAuth/Post';
  static const String register = '/api/Person/Add';
  static const String profile = '/api/ProfileEndpoint/GetUserInfo';

  /// POST /Verification — confirms the emailed code for a new account.
  /// Note the route has no `/api` prefix on this backend.
  static const String verify = '/Verification';

  /// DELETE /api/LoginAuth/Delete — invalidates the token server-side.
  /// Without it, "log out" only forgot the token on the device while it
  /// stayed valid on the backend.
  static const String logout = '/api/LoginAuth/Delete';

  // ─── Profile settings (editable account details) ────────
  static const String profileSettingsGet = '/api/ProfileSettings/Get';
  static const String profileSettingsEdit = '/api/ProfileSettings/Edit';

  // ─── VetStation (all AllowAnonymous — guest-browsable) ──
  static const String vetStationSearch = '/api/VetStationSearch';
  static const String vetStationGetAll = '/api/VetStation/GetAll';
  static const String vetStationGetById = '/api/VetStation/Get';

  // ─── Employee / TimeSlot (both [Authorize] on the backend —
  // not wired yet; see chat notes on the guest-first conflict) ──
  static const String employeeByStation = '/api/Employee/GetByVetStationId';

  /// Role-filtered variants of the above. Same paginated envelope, but
  /// the backend narrows by TPT subtype (Vet / Nurse / Barber) — which is
  /// cheaper and more correct than pulling everyone and filtering by
  /// RoleId on the device.
  static const String employeeVetsByStation = '/api/Employee/GetVetsByVetStationId';
  static const String employeeNursesByStation = '/api/Employee/GetNursesByVetStationId';
  static const String employeeBarbersByStation = '/api/Employee/GetBarbersByVetStationId';
  static const String timeSlotGet = '/api/TimeSlot/Get';

  // ─── Animal / Pets ──────────────────────────────────────
  static const String animalByOwner = '/api/Animal/GetByOwnerId';
  static const String petsSave = '/api/PetsUpdateOrInsert/Save';
  static const String petsSoftDelete = '/api/Pets/SoftDelete';

  // ─── Species / Breed ────────────────────────────────────
  static const String speciesGetAll = '/api/SpeciesGetAll/Get';
  static const String breedBySpecies = '/api/BreedGetBySpecies/Get';

  // ─── Appointments ───────────────────────────────────────
  static const String appointmentByCustomer = '/api/Appointment/GetByCustomerId';
  static const String appointmentAdd = '/api/Appointment/Add';
  static const String appointmentCancel = '/api/Appointment/Cancel';

  /// PUT /api/Appointment/Reschedule — moves an existing appointment to
  /// another free slot of the SAME employee (the backend enforces that).
  static const String appointmentReschedule = '/api/Appointment/Reschedule';

  // ─── Reviews ────────────────────────────────────────────

  /// GET — anonymous. Score, star distribution and the review list for one
  /// clinic, so a guest can read them before ever signing up.
  static const String reviewByVetStation = '/api/Review/GetByVetStation';

  /// POST — authenticated. Rates one past appointment; the backend checks
  /// the visit is this person's, already happened, and is not yet rated.
  static const String reviewAdd = '/api/Review/Add';

  /// GET — authenticated. Past visits of mine that still have no review.
  static const String reviewPending = '/api/Review/Pending';
}
