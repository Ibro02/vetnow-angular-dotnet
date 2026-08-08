import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

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

  /// Stores the token from a successful login, then tries to fetch the
  /// full profile (name, id, email) from the backend. If that call
  /// fails for any reason, we still consider the person logged in —
  /// [fallbackName] (whatever they typed to sign in) is used instead so
  /// the UI still has something reasonable to show.
  Future<void> loginWithToken(String newToken, {String? fallbackName}) async {
    isLoggedIn = true;
    token = newToken;
    displayName = fallbackName;
    notifyListeners();

    try {
      final profile = await AuthApiService.getProfile(newToken);
      userId = profile['id'] as int?;
      final first = profile['firstName'] as String? ?? '';
      final last = profile['lastName'] as String? ?? '';
      final fullName = '$first $last'.trim();
      displayName = fullName.isNotEmpty ? fullName : (profile['username'] as String? ?? fallbackName);
      email = profile['email'] as String?;
      notifyListeners();
    } catch (_) {
      // Keep the session — just without the extra profile details.
    }
  }

  void logOut() {
    isLoggedIn = false;
    token = null;
    userId = null;
    displayName = null;
    email = null;
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
