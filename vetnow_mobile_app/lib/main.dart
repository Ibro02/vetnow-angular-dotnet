import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/root_shell.dart';
import 'state/auth_state.dart';
import 'state/locale_state.dart';

void main() {
  runApp(const VetNowApp());
}

class VetNowApp extends StatefulWidget {
  const VetNowApp({super.key});

  @override
  State<VetNowApp> createState() => _VetNowAppState();
}

class _VetNowAppState extends State<VetNowApp> {
  final _authState = AuthState();
  final _localeState = LocaleState();

  @override
  void dispose() {
    _authState.dispose();
    _localeState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      notifier: _localeState,
      child: AnimatedBuilder(
        animation: _localeState,
        builder: (context, _) {
          return AuthScope(
            notifier: _authState,
            child: MaterialApp(
              title: 'VetNow',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: _localeState.locale,
              supportedLocales: const [
                Locale('bs'),
                Locale('hr'),
                Locale('sr'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Guest-first: the app opens straight into Explore. Login is
              // only requested later, right before confirming a booking (see
              // BookingScreen) or when tapping Appointments/Profile as a guest.
              home: const RootShell(),
            ),
          );
        },
      ),
    );
  }
}
