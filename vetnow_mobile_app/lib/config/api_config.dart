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

  // ─── VetStation (all AllowAnonymous — guest-browsable) ──
  static const String vetStationSearch = '/api/VetStationSearch';
  static const String vetStationGetAll = '/api/VetStation/GetAll';
  static const String vetStationGetById = '/api/VetStation/Get';

  // ─── Employee / TimeSlot (both [Authorize] on the backend —
  // not wired yet; see chat notes on the guest-first conflict) ──
  static const String employeeByStation = '/api/Employee/GetByVetStationId';
  static const String timeSlotGet = '/api/TimeSlot/Get';

  // ─── Animal / Pets ──────────────────────────────────────
  static const String animalByOwner = '/api/Animal/GetByOwnerId';
  static const String petsSave = '/api/PetsUpdateOrInsert/Save';

  // ─── Species / Breed ────────────────────────────────────
  static const String speciesGetAll = '/api/SpeciesGetAll/Get';
  static const String breedBySpecies = '/api/BreedGetBySpecies/Get';

  // ─── Appointments ───────────────────────────────────────
  static const String appointmentByCustomer = '/api/Appointment/GetByCustomerId';
  static const String appointmentAdd = '/api/Appointment/Add';
}
