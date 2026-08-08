import 'package:flutter/material.dart';

/// Tracks the app's current language (bs / hr / sr). Defaults to
/// Bosnian. Swap for shared_preferences persistence later — for now
/// it just lives in memory for the session, same as AuthState.
class LocaleState extends ChangeNotifier {
  Locale locale = const Locale('bs');

  void setLocale(Locale newLocale) {
    if (locale == newLocale) return;
    locale = newLocale;
    notifyListeners();
  }
}

class LocaleScope extends InheritedNotifier<LocaleState> {
  const LocaleScope({
    super.key,
    required LocaleState super.notifier,
    required super.child,
  });

  static LocaleState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in widget tree');
    return scope!.notifier!;
  }
}
