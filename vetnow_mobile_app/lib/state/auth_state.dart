import 'dart:async';

import 'package:flutter/material.dart';
import '../services/account_cache.dart';
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

  /// Set by [loginWithToken] and cleared by whoever acts on it.
  ///
  /// The sign-in screen is a route pushed over whichever tab the
  /// person happened to be on, so popping it used to drop them back
  /// on Profile or Appointments. The shell watches this to bring them
  /// to Explore instead, which is the screen the app is actually for.
  ///
  /// Deliberately not just "isLoggedIn went from false to true":
  /// [restore] does that too, at launch, and would then fight a deep
  /// link that had already chosen a tab.
  bool justSignedIn = false;

  /// True when the session ended because the backend refused the
  /// token, rather than because anybody asked to sign out. Cleared on
  /// the next successful sign-in.
  bool sessionExpired = false;

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
    justSignedIn = true;
    sessionExpired = false;
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

  /// The account's photograph, base64, once something has fetched it.
  ///
  /// Deliberately not filled at sign-in. The login path asks
  /// GetUserInfo, which does not return a picture, and adding a second
  /// round-trip to every sign-in for an avatar would be spending time in
  /// the one place people are watching the clock. Profile fills it in
  /// when it loads, which is also the first place it is shown.
  String? photoBase64;

  /// Records a photo fetched elsewhere, or one that was just saved.
  void updatePhoto(String? base64) {
    if (base64 == photoBase64) return;
    photoBase64 = base64;
    notifyListeners();
  }

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
    final oldUserId = userId;

    isLoggedIn = false;
    token = null;
    userId = null;
    displayName = null;
    email = null;
    username = null;
    photoBase64 = null;
    notifyListeners();

    // Forget it locally first: even if the network call below fails, the
    // next launch must not silently sign this person back in.
    await SessionStore.clear();

    // Somebody else's pets left on a shared phone after they have
    // signed out is not a caching decision, it is a leak.
    if (oldUserId != null) await AccountCache.clearFor(oldUserId);

    if (oldToken != null) await AuthApiService.logout(oldToken);
  }

  /// The backend stopped accepting the session token.
  ///
  /// Different from [logOut] in two ways that matter. There is no
  /// server call — the token is already refused, and asking it to be
  /// revoked would only fail again. And [sessionExpired] is left set,
  /// so the sign-in prompt can say why the person is suddenly looking
  /// at it instead of at their appointments.
  ///
  /// Before this existed, a token that had expired overnight meant
  /// every screen behind the login showed "Request failed (401)." with
  /// a retry button that could only ever fail the same way.
  void expire() {
    if (!isLoggedIn) return;
    final goneUserId = userId;

    isLoggedIn = false;
    sessionExpired = true;
    token = null;
    userId = null;
    displayName = null;
    email = null;
    username = null;
    photoBase64 = null;
    unawaited(SessionStore.clear());
    if (goneUserId != null) unawaited(AccountCache.clearFor(goneUserId));
    notifyListeners();
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
