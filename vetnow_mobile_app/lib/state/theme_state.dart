import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';

/// Light, dark, or whatever the phone is set to.
///
/// Defaults to following the system, which is what people expect and what
/// stops the app being the one bright rectangle at midnight. The choice
/// is remembered, because a theme that resets on every launch is worse
/// than not offering one.
class ThemeState extends ChangeNotifier {
  static const _key = 'vetnow.theme.mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// The brightness actually in effect, given [platform] for system mode.
  Brightness resolve(Brightness platform) => switch (_mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => platform,
      };

  /// Reads the saved choice. Runs before the first frame, so a failure
  /// has to fall back silently rather than block startup.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      if (stored == null) return;

      _mode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // Following the system is a fine answer when we can't read a choice.
    }
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // The choice still applies for this run; it just won't be remembered.
    }
  }
}

/// Makes [ThemeState] reachable from anywhere in the tree, the same way
/// the locale and the session already are.
class ThemeScope extends InheritedNotifier<ThemeState> {
  const ThemeScope({
    super.key,
    required ThemeState super.notifier,
    required super.child,
  });

  static ThemeState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    return scope!.notifier!;
  }
}

/// Applies [brightness] to the token palette before anything is built.
///
/// [AppColors] resolves its neutrals against a single static, so it has
/// to be set before the widgets that read it are constructed — not during
/// them. Calling this at the top of the root's build is what keeps the
/// two in step.
void applyPaletteBrightness(Brightness brightness) {
  AppColors.brightness = brightness;
}
