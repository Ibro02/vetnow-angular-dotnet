// The theme switch, end to end: what gets remembered, what "follow the
// system" actually resolves to, and whether a selected row stays visible
// once the sheet itself goes dark.
//
// That last one is the case worth having a test for. The selected row
// used to be painted with the ink gradient, which is the strongest
// highlight there is on a white sheet and very nearly the sheet itself
// on a dark one — so in dark mode the row marked as chosen was the one
// row you could not tell had been chosen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/config/theme.dart';
import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/state/theme_state.dart';
import 'package:vetnow_mobile/widgets/theme_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The palette is a process-wide static; leaving a test in dark mode
    // would quietly change what every later test renders.
    applyPaletteBrightness(Brightness.light);
  });

  tearDown(() => applyPaletteBrightness(Brightness.light));

  group('ThemeState', () {
    test('follows the system until told otherwise', () {
      final state = ThemeState();
      expect(state.mode, ThemeMode.system);
      expect(state.resolve(Brightness.dark), Brightness.dark);
      expect(state.resolve(Brightness.light), Brightness.light);
    });

    test('an explicit choice ignores what the phone is set to', () {
      final state = ThemeState();
      state.set(ThemeMode.dark);
      expect(state.resolve(Brightness.light), Brightness.dark);

      state.set(ThemeMode.light);
      expect(state.resolve(Brightness.dark), Brightness.light);
    });

    test('the choice survives a restart', () async {
      await ThemeState().set(ThemeMode.dark);

      final next = ThemeState();
      await next.restore();
      expect(next.mode, ThemeMode.dark);
    });

    test('restoring with nothing saved leaves it on system', () async {
      final state = ThemeState();
      await state.restore();
      expect(state.mode, ThemeMode.system);
    });

    test('a value we never wrote falls back to system rather than throwing',
        () async {
      SharedPreferences.setMockInitialValues({'vetnow.theme.mode': 'sepia'});

      final state = ThemeState();
      await state.restore();
      expect(state.mode, ThemeMode.system);
    });

    test('setting the mode already in effect notifies nobody', () {
      final state = ThemeState();
      var notifications = 0;
      state.addListener(() => notifications++);

      state.set(ThemeMode.system);
      expect(notifications, 0);

      state.set(ThemeMode.dark);
      expect(notifications, 1);
    });
  });

  group('palette', () {
    test('dark mode flips the neutrals but keeps the brand colours', () {
      final lightBg = AppColors.bg;
      final lightText = AppColors.text;
      const brand = AppColors.primary;

      applyPaletteBrightness(Brightness.dark);

      expect(AppColors.bg, isNot(lightBg));
      expect(AppColors.text, isNot(lightText));
      expect(AppColors.primary, brand);
    });

    test('the selected sweep changes so it never matches its own surface', () {
      applyPaletteBrightness(Brightness.light);
      final onLight = AppGradients.selected.colors;
      final solidOnLight = AppGradients.selectedSolid;

      applyPaletteBrightness(Brightness.dark);

      expect(AppGradients.selected.colors, isNot(onLight));
      expect(AppGradients.selectedSolid, isNot(solidOnLight));
    });
  });

  group('theme picker', () {
    Future<ThemeState> openSheet(WidgetTester tester) async {
      final state = ThemeState();

      await tester.pumpWidget(
        ThemeScope(
          notifier: state,
          child: MaterialApp(
            locale: const Locale('bs'),
            supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.current,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showThemePicker(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return state;
    }

    testWidgets('offers all three options, system first', (tester) async {
      await openSheet(tester);

      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));
      final system = tester.getTopLeft(find.text(l10n.themeSystem)).dy;
      final light = tester.getTopLeft(find.text(l10n.themeLight)).dy;
      final dark = tester.getTopLeft(find.text(l10n.themeDark)).dy;

      expect(system, lessThan(light));
      expect(light, lessThan(dark));
    });

    testWidgets('picking dark applies it and closes the sheet', (tester) async {
      final state = await openSheet(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));

      await tester.tap(find.text(l10n.themeDark));
      await tester.pumpAndSettle();

      expect(state.mode, ThemeMode.dark);
      expect(find.text(l10n.themeLight), findsNothing);
    });

    testWidgets('each option is announced as a selectable button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openSheet(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));

      // Exactly the label, once. The row used to carry it twice — on the
      // Semantics node and again on the Text underneath — so every option
      // was read out as "Follow the phone, Follow the phone".
      expect(
        tester.getSemantics(find.bySemanticsLabel(l10n.themeSystem)),
        matchesSemantics(
          label: l10n.themeSystem,
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      // The other two are the same control in its unselected state.
      expect(
        tester.getSemantics(find.bySemanticsLabel(l10n.themeDark)),
        matchesSemantics(
          label: l10n.themeDark,
          isButton: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the selected row is not painted in the dark sheet\'s own ink',
        (tester) async {
      applyPaletteBrightness(Brightness.dark);
      await openSheet(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));

      final row = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text(l10n.themeSystem),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final gradient =
          (row.decoration as BoxDecoration).gradient as LinearGradient;

      expect(gradient.colors, isNot(contains(AppColors.ink)));
      expect(gradient.colors, AppGradients.brand.colors);
    });
  });
}
