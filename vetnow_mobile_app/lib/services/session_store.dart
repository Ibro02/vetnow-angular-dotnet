import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth session between app launches.
///
/// The token goes into platform-backed secure storage (Android Keystore /
/// iOS Keychain) rather than plain preferences — it is a credential that
/// grants full access to the account's pets, appointments and profile, so
/// it should not sit in a world-readable file.
///
/// Only the token is persisted. Everything else about the session (name,
/// id, email) is refetched from the backend on restore, so a stale name or
/// a changed email can never linger on the device.
class SessionStore {
  SessionStore._();

  /// Default options are already the strong ones in flutter_secure_storage
  /// 11.x on Android: AES/GCM for the data, RSA-OAEP key wrapping in the
  /// Keystore. No extra configuration needed — and the old
  /// `encryptedSharedPreferences` flag no longer exists in this version.
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'vetnow.auth.token';

  /// Saves the token so the next launch can restore the session.
  ///
  /// Every call is wrapped: on a device where the keystore is unavailable
  /// (some rooted or heavily customised ROMs) storage throws, and failing
  /// to *remember* a session must never break signing in. Worst case the
  /// person stays logged in only for this run.
  static Future<void> save(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Non-fatal — see above.
    }
  }

  static Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Nothing to do; the in-memory session is cleared either way.
    }
  }
}
