import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/session_store.dart';

/// Auth state shared across the app, now backed by the real VetStat API
/// (see services/auth_api_service.dart). Holds the raw token returned by
/// POST /api/LoginAuth/Post — the same value the backend's legacy
/// header-auth fallback checks under the `my-auth-token` header.
///
/// Usage:
///   final auth = AuthScope.of(context);
///   await auth.loginWithToken(token, fallbackName: usernameOrEmail);
///   if (auth.isLoggedIn) { ... }
class AuthState extends ChangeNotifier {
  bool isLoggedIn = false;
  String? token;
  int? userId;
  String? displayName;
  String? email;

  /// True while [restore] is checking a saved token at startup. The app
  /// shows a splash during this so it never flashes the logged-out shell
  /// at someone who is, in fact, signed in.
  bool isRestoring = true;

  /// Stores the token from a successful login, then tries to fetch the
  /// full profile (name, id, email) from the backend. If that call
  /// fails for any reason, we still consider the person logged in —
  /// [fallbackName] (whatever they typed to sign in) is used instead so
  /// the UI still has something reasonable to show.
  ///
  /// [remember] persists the token so the next launch restores the
  /// session. It is driven by the "keep me signed in" checkbox; when it
  /// is false the session lives only until the app is closed.
  Future<void> loginWithToken(String newToken, {String? fallbackName, bool remember = false}) async {
    isLoggedIn = true;
    token = newToken;
    displayName = fallbackName;
    username = fallbackName;
    notifyListeners();

    if (remember) await SessionStore.save(newToken);

    await _loadProfile(newToken, fallbackName: fallbackName);
  }

  /// Restores a saved session at startup.
  ///
  /// The token is verified against the backend before being trusted — an
  /// expired or revoked one must not leave the app showing a logged-in
  /// shell whose every request then fails. If verification fails the
  /// stored token is dropped and the person simply starts as a guest.
  Future<void> restore() async {
    try {
      final saved = await SessionStore.read();
      if (saved == null || saved.isEmpty) return;

      // getProfile both validates the token and gives us the session
      // details in one round-trip.
      final profile = await AuthApiService.getProfile(saved);

      isLoggedIn = true;
      token = saved;
      _applyProfile(profile);
    } catch (_) {
      // Invalid, expired, or backend unreachable — start clean rather
      // than pretending to be signed in.
      await SessionStore.clear();
      isLoggedIn = false;
      token = null;
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String activeToken, {String? fallbackName}) async {
    try {
      final profile = await AuthApiService.getProfile(activeToken);
      _applyProfile(profile, fallbackName: fallbackName);
      notifyListeners();
    } catch (_) {
      // Keep the session — just without the extra profile details.
    }
  }

  void _applyProfile(Map<String, dynamic> profile, {String? fallbackName}) {
    userId = profile['id'] as int?;
    final first = profile['firstName'] as String? ?? '';
    final last = profile['lastName'] as String? ?? '';
    final fullName = '$first $last'.trim();
    username = profile['username'] as String? ?? fallbackName;
    displayName = fullName.isNotEmpty ? fullName : (username ?? fallbackName);
    email = profile['email'] as String?;
  }

  /// Username the person signed in with. The profile-edit endpoint
  /// requires it on every save, while the GET response doesn't return it.
  String? username;

  /// Reflects a just-saved profile edit in the session, so the header
  /// stops showing the old name before the next login.
  void updateDisplayName(String name, {String? email}) {
    displayName = name;
    if (email != null && email.isNotEmpty) this.email = email;
    notifyListeners();
  }

  /// Signs out. The token is invalidated on the server first, then
  /// forgotten locally — previously only the local half happened, so the
  /// token stayed usable on the backend after "log out".
  ///
  /// Local state is cleared even if the server call fails, so signing out
  /// can never leave the person stuck in a half-logged-in state.
  Future<void> logOut() async {
    final oldToken = token;

    isLoggedIn = false;
    token = null;
    userId = null;
    displayName = null;
    email = null;
    username = null;
    notifyListeners();

    // Forget it locally first: even if the network call below fails, the
    // next launch must not silently sign this person back in.
    await SessionStore.clear();

    if (oldToken != null) await AuthApiService.logout(oldToken);
  }
}

class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({
    super.key,
    required AuthState super.notifier,
    required super.child,
  });

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }
}
