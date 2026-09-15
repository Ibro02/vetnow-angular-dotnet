import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/root_shell.dart';
import 'services/crash_log.dart';
import 'services/deep_links.dart';
import 'state/auth_state.dart';
import 'state/locale_state.dart';
import 'state/theme_state.dart';
import 'widgets/paw_loader.dart';

void main() {
  // Before anything else, so a failure during the very first frame is
  // recorded rather than lost.
  CrashLog.install();

  // runZonedGuarded catches what the other two channels cannot: an error
  // thrown inside a callback that no one awaited, in code that ran
  // outside the framework's own error zone.
  runZonedGuarded(
    () => runApp(const VetNowApp()),
    (error, stack) => CrashLog.record(error, stack, context: 'zone', fatal: true),
  );
}

class VetNowApp extends StatefulWidget {
  const VetNowApp({super.key});

  @override
  State<VetNowApp> createState() => _VetNowAppState();
}

class _VetNowAppState extends State<VetNowApp> {
  final _authState = AuthState();
  final _localeState = LocaleState();
  final _themeState = ThemeState();

  /// The link waiting to be acted on, if the app was opened by one.
  final _pendingLink = ValueNotifier<DeepLink?>(null);
  late final DeepLinkListener _deepLinks;

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
    _themeState.restore();

    // Both channels matter: the link that launched a cold start arrives
    // once at startup, and later taps arrive on a stream. Handling only
    // one of the two means half of all links quietly open the front door
    // instead of the page they name.
    _deepLinks = DeepLinkListener(onLink: (link) => _pendingLink.value = link);
    _deepLinks.start();
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    _pendingLink.dispose();
    _authState.dispose();
    _localeState.dispose();
    _themeState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The palette resolves against a single static, so it has to be set
    // before the widgets that read it are built — and re-set whenever
    // either the choice or the system setting changes, which is why this
    // sits at the top of build rather than in initState.
    final platform = MediaQuery.platformBrightnessOf(context);

    return DeepLinkScope(
      notifier: _pendingLink,
      child: ThemeScope(
        notifier: _themeState,
        child: LocaleScope(
          notifier: _localeState,
          child: AnimatedBuilder(
            animation: Listenable.merge([_localeState, _themeState]),
            builder: (context, _) {
              applyPaletteBrightness(_themeState.resolve(platform));

              return AuthScope(
                notifier: _authState,
                child: MaterialApp(
                  title: 'VetNow',
                  debugShowCheckedModeBanner: false,
                  // One ThemeData either way: `current` reads the palette that
                  // was just applied. Passing it as both theme and darkTheme
                  // keeps Material from swapping in its own defaults when the
                  // system flips while the app is open.
                  theme: AppTheme.current,
                  darkTheme: AppTheme.current,
                  themeMode: _themeState.mode,
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
                  // Keyed on the brightness so the whole tree is rebuilt when
                  // the theme flips.
                  //
                  // The palette is a static rather than an InheritedWidget, so
                  // nothing below depends on it the way Flutter tracks
                  // dependencies — a new ThemeData alone repaints Material's
                  // own chrome and leaves every widget that read AppColors
                  // directly showing the old colours. Changing the key is what
                  // forces those to build again.
                  //
                  // The cost is that screen state is discarded on a switch,
                  // which is why the clinic list is cached: it comes straight
                  // back rather than flashing skeletons at someone who only
                  // changed a setting.
                  home: KeyedSubtree(
                    key: ValueKey(AppColors.brightness),
                    child: AnimatedBuilder(
                      animation: _authState,
                      builder: (context, _) =>
                          _authState.isRestoring ? const _SessionSplash() : const RootShell(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
