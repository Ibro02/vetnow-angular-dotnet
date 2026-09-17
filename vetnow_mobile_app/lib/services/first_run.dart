import 'package:shared_preferences/shared_preferences.dart';

/// Whether this is the first time the app has been opened.
///
/// Used for one thing only: deciding whether to show the three cards
/// that explain what VetNow is. Kept apart from the session, because a
/// person who signs out has not forgotten what the app does.
class FirstRun {
  FirstRun._();

  static const _key = 'vetnow.onboarding.seen';

  /// True until [markSeen] has been called on this device.
  ///
  /// A read that fails counts as "already seen". The failure mode
  /// matters: getting the introduction once too rarely costs nothing,
  /// while getting it on every launch because SharedPreferences is
  /// unavailable would be the most irritating bug in the app.
  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_key) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Nothing to do. Worst case it is shown again next launch.
    }
  }

  /// For the diagnostics screen, and for anyone testing the flow.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // As above.
    }
  }
}
