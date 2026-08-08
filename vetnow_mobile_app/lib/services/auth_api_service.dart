import '../config/api_config.dart';
import 'api_client.dart';

/// Thrown specifically when the backend says the account exists but
/// isn't email-verified yet (LoginAuthPostEndpoint returns 401 with
/// needsVerification: true and sends a fresh code to the user's email).
class NeedsVerificationException implements Exception {
  final String message;
  NeedsVerificationException(this.message);
}

class AuthApiService {
  AuthApiService._();

  /// POST /api/LoginAuth/Post — returns a raw token string on success.
  static Future<String> login({required String usernameOrEmail, required String password}) async {
    try {
      final result = await ApiClient.post(ApiConfig.login, body: {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      });
      return result as String;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && e.message.toLowerCase().contains('verif')) {
        throw NeedsVerificationException(e.message);
      }
      rethrow;
    }
  }

  /// POST /api/Person/Add — registers a new account. Note: new accounts
  /// are unverified by default on this backend (Person.Verified starts
  /// false), so logging in immediately after will hit the
  /// needs-verification path until email verification is implemented
  /// in the app.
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    final result = await ApiClient.post(ApiConfig.register, body: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'password': password,
    });
    return result as Map<String, dynamic>;
  }

  /// GET /api/ProfileEndpoint/GetUserInfo — fetches the logged-in
  /// user's profile using their auth token.
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final result = await ApiClient.get(ApiConfig.profile, token: token);
    return result as Map<String, dynamic>;
  }
}
