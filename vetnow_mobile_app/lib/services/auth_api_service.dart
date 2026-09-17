import '../config/api_config.dart';
import 'api_client.dart';

/// Thrown specifically when the backend says the account exists but
/// isn't email-verified yet (LoginAuthPostEndpoint returns 401 with
/// needsVerification: true and sends a fresh code to the user's email).
class NeedsVerificationException implements Exception {
  final String message;

  /// Id of the account awaiting verification. The backend returns it
  /// alongside the 401 precisely so the client can continue into the
  /// verification step — POST /Verification needs it together with the
  /// emailed code. Null only if the backend answered in an older shape.
  final int? userId;

  NeedsVerificationException(this.message, {this.userId});
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
      // The backend answers an unverified account with 401 and a body of
      // {userId, needsVerification: true}, and emails a fresh code at the
      // same time. Detect it by that flag rather than by wording, so a
      // translated or reworded message can't break the flow; the text
      // check stays as a fallback for older responses.
      final body = e.body;
      final flagged = body is Map && body['needsVerification'] == true;

      if (e.statusCode == 401 && (flagged || e.message.toLowerCase().contains('verif'))) {
        throw NeedsVerificationException(
          e.message,
          userId: body is Map ? body['userId'] as int? : null,
        );
      }
      rethrow;
    }
  }

  /// POST /Verification — confirms the emailed code.
  ///
  /// On success the backend marks the account verified AND issues a
  /// session token, so the person lands straight in the app instead of
  /// being sent back to the login form.
  static Future<String> verify({required int userId, required String code}) async {
    final result = await ApiClient.post(ApiConfig.verify, body: {
      'userId': userId,
      'token': code.trim(),
    });

    if (result is Map && result['token'] is String) return result['token'] as String;
    if (result is String) return result;
    throw ApiException(200, 'Unexpected verification response.');
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

  /// DELETE /api/LoginAuth/Delete — invalidates the token on the server.
  ///
  /// Deliberately never throws: logging out must always succeed from the
  /// person's point of view. If the network is down we still forget the
  /// token locally; the server-side one expires on its own.
  static Future<void> logout(String token) async {
    try {
      await ApiClient.delete(ApiConfig.logout, token: token);
    } catch (_) {
      // Local sign-out proceeds regardless.
    }
  }
}
