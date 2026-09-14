import '../config/api_config.dart';
import 'api_client.dart';

/// Editable account details, mirroring ProfileSettingsGetResponse /
/// ProfileSettingsEditRequest on the backend.
///
/// Note the asymmetry in the backend contract: the GET response does not
/// include `Username`, but the PUT request requires it. That is why the
/// edit screen carries the username it already knows from the session and
/// sends it back unchanged.
class ProfileSettings {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? city;
  final String? country;
  final String? address;
  final String? picture;

  const ProfileSettings({
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.city,
    this.country,
    this.address,
    this.picture,
  });

  String get fullName => [firstName, lastName].where((p) => p != null && p.trim().isNotEmpty).join(' ').trim();

  factory ProfileSettings.fromJson(Map<String, dynamic> json) => ProfileSettings(
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        city: json['city'] as String?,
        country: json['country'] as String?,
        address: json['address'] as String?,
        picture: json['picture'] as String?,
      );
}

class ProfileSettingsApiService {
  ProfileSettingsApiService._();

  /// GET /api/ProfileSettings/Get — [Authorize]. The person is resolved
  /// from the token, so no id is sent.
  static Future<ProfileSettings> get(String token) async {
    final result = await ApiClient.get(ApiConfig.profileSettingsGet, token: token);
    return ProfileSettings.fromJson(result as Map<String, dynamic>);
  }

  /// PUT /api/ProfileSettings/Edit — [Authorize].
  ///
  /// `password` is optional: sending null leaves the current one alone.
  /// Only send it when the person actually typed a new one.
  static Future<void> edit({
    required String token,
    required String username,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? city,
    String? country,
    String? address,
    String? password,
  }) async {
    await ApiClient.put(
      ApiConfig.profileSettingsEdit,
      token: token,
      body: {
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'city': city,
        'country': country,
        'address': address,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
  }
}
