import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/root_shell.dart';
import 'state/auth_state.dart';
import 'state/locale_state.dart';
import 'widgets/paw_loader.dart';

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

  /// Exposed for widget tests, which assert that session restore always
  /// settles rather than leaving the app on the splash. Not used by app
  /// code — screens reach the same object through [AuthScope].
  @visibleForTesting
  AuthState get debugAuthState => _authState;

  @override
  void initState() {
    super.initState();
    // Check for a saved session before the first screen settles. Runs
    // unawaited on purpose — the UI shows a splash while `isRestoring`
    // is true and rebuilds when it flips.
    _authState.restore();
  }

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
              //
              // While a saved session is being verified we hold on a splash
              // instead of the shell, so someone who is signed in never sees
              // "Appointments" flash its guest prompt first.
              home: AnimatedBuilder(
                animation: _authState,
                builder: (context, _) =>
                    _authState.isRestoring ? const _SessionSplash() : const RootShell(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Brief brand screen shown while a saved session is verified at startup.
///
/// Uses the same ink gradient and sheen as the rest of the app so the
/// launch reads as one continuous surface rather than a blank frame.
class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.ink),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
            Center(child: PawLoader(size: 44, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
