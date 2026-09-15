// ═══════════════════════════════════════════════════════════
// VetNow Design Tokens — Flutter port of frontend/src/styles/theme.css
// Single source of truth for colors, typography, spacing, radius.
// Keep this in sync with the Angular theme so both apps stay
// visually identical.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// The app's colours, in whichever theme is currently active.
///
/// The brand — teal, green, gold, ink — is deliberately identical in both
/// themes. That is what a brand is: dark mode is not a different identity,
/// it is the same identity on a dark surface. Only the neutrals flip, and
/// they flip together, which is why they live behind getters rather than
/// being read straight off a const.
///
/// [brightness] is set once at the root, before the first frame, from the
/// person's choice or the system setting. Reading a colour anywhere else
/// then resolves against it. The cost of that is that these cannot be
/// `const` any more — the compiler points at every site that assumed they
/// were, which is exactly the kind of change worth having checked.
class AppColors {
  AppColors._();

  /// Set by the root widget. Everything below resolves against it.
  static Brightness brightness = Brightness.light;

  static bool get _dark => brightness == Brightness.dark;

  // ─── Brand — identical in both themes ───────────────────
  static const primary = Color(0xFF33B3AE);
  static const primaryLight = Color(0xFF5CCCC7);
  static const primaryDark = Color(0xFF28918D);

  static const accent = Color(0xFF3FCA93);
  static const accentHover = Color(0xFF35B882);
  static const accentActive = Color(0xFF2EA574);

  /// Warm gold for ratings and "premium" touches — deliberately outside
  /// the teal/green pair so 4.9★ actually pops on a card.
  static const gold = Color(0xFFE8A73C);

  /// Deep ink behind heroes and app bars. Already dark, so it does not
  /// change: the headers look the same in both themes, which is what
  /// keeps the app recognisable when someone flips the switch.
  static const ink = Color(0xFF0F2E2C);

  // ─── Translucent brand tints ────────────────────────────
  //
  // Alpha-based, so they sit correctly on a light or a dark surface
  // without being redefined — but they need a touch more presence on
  // dark, where a 8% wash all but disappears.
  static Color get primary50 => _dark ? const Color(0x2633B3AE) : const Color(0x1433B3AE);
  static Color get primary100 => _dark ? const Color(0x3D33B3AE) : const Color(0x2633B3AE);
  static Color get accent50 => _dark ? const Color(0x263FCA93) : const Color(0x143FCA93);

  // ─── Neutrals — these are what dark mode actually changes ──
  static Color get bg => _dark ? const Color(0xFF0E1513) : const Color(0xFFFFFFFF);

  /// The page behind everything.
  static Color get bgSoft => _dark ? const Color(0xFF0B1211) : const Color(0xFFFAF9F6);

  /// Inset wells: chip backgrounds, empty-state circles, tab bars.
  static Color get bgMuted => _dark ? const Color(0xFF1A2422) : const Color(0xFFF3F4F6);

  /// Cards and sheets. Deliberately lighter than [bgSoft] in both themes,
  /// so a card always reads as sitting above the page.
  static Color get surface => _dark ? const Color(0xFF15201E) : const Color(0xFFFFFFFF);
  static Color get surfaceHover => _dark ? const Color(0xFF1C2926) : const Color(0xFFF9FAFB);

  static Color get border => _dark ? const Color(0xFF2A3733) : const Color(0xFFE5E7EB);
  static Color get borderLight => _dark ? const Color(0xFF1F2C29) : const Color(0xFFF0F0F0);

  static Color get text => _dark ? const Color(0xFFECF1EF) : const Color(0xFF111827);
  static Color get textSecondary => _dark ? const Color(0xFFA9B8B3) : const Color(0xFF6B7280);
  static Color get textMuted => _dark ? const Color(0xFF7C8C87) : const Color(0xFF9CA3AF);

  /// Always white — it sits on brand or ink, which never change.
  static const textInverse = Color(0xFFFFFFFF);

  // ─── Semantic ───────────────────────────────────────────
  static const danger = Color(0xFFEF4444);
  static const dangerHover = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);

  // Tinted backgrounds behind those. On dark these have to be mixed from
  // the dark surface rather than from white, or a "soft" red panel comes
  // out brighter than the page it is warning you about.
  static Color get dangerSoft => _dark ? const Color(0xFF2A1A1A) : const Color(0xFFFEF2F2);
  static Color get warningSoft => _dark ? const Color(0xFF2A2318) : const Color(0xFFFFFBEB);
  static Color get successSoft => _dark ? const Color(0xFF13241E) : const Color(0xFFECFDF5);
  static Color get goldSoft => _dark ? const Color(0xFF2A2318) : const Color(0xFFFDF3E2);

  // ─── Legacy aliases (from tailwind.config.js) ────────────
  static const lightGreen = Color(0xFF3FCA93);
  static const turquoiseBlue = Color(0xFF33B3AE);
  static const secondary = Color(0xFF868686);
  static Color get beige => bgSoft;
  static const roseModified = Color(0xFFFFC3AE);
  static const lightGreenModified = Color(0xFFF1F6BE);
}

class AppRadius {
  AppRadius._();

  static const sm = 6.0; // 0.375rem
  static const md = 8.0; // 0.5rem
  static const lg = 12.0; // 0.75rem
  static const xl = 16.0; // 1rem — used for cards
  static const xl2 = 20.0; // 1.25rem
  static const full = 9999.0;
}

class AppSpacing {
  AppSpacing._();

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const pagePadding = 24.0;
}

class AppShadows {
  AppShadows._();

  /// Resting card depth.
  ///
  /// Two layers on purpose: a tight contact shadow right under the edge
  /// plus a wider ambient one. A single blur reads as a grey smudge —
  /// this reads as a card actually sitting on the surface, which is what
  /// makes the whole list feel crisp rather than flat.
  static const card = [
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  /// One step above [card] — for the element the eye should land on
  /// first in a group (a featured clinic, the selected pet).
  static const lifted = [
    BoxShadow(
      color: Color(0x0F101828),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 22,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x14101828),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x0D101828),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Colored glow under a hero / primary CTA — the "premium" touch.
  /// Layered the same way: a tight saturated core and a wide soft halo,
  /// so the color reads as light coming off the button.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.30),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
      ];
}

/// Gradients used across the app. Defined once so a hero on Profile and a
/// hero on Appointments are literally the same sweep, not two hand-mixed
/// approximations that drift apart.
class AppGradients {
  AppGradients._();

  /// The dark "serious vet" surface behind heroes and app bars.
  static const ink = LinearGradient(
    colors: [AppColors.ink, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Brand sweep for primary actions and selected states.
  static const brand = LinearGradient(
    colors: [AppColors.primary, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm sweep for ratings, "premium" and member badges.
  static const gold = LinearGradient(
    colors: [Color(0xFFF0B857), AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The sweep behind a *selected* chip, tab or row.
  ///
  /// Ink on a white page is the strongest selected state there is. On a
  /// dark page it is very nearly the page itself, so the selection all
  /// but disappears — there the brand sweep carries it instead. One
  /// definition, so every chip and tab in the app agrees.
  static LinearGradient get selected => AppColors.brightness == Brightness.dark
      ? brand
      : const LinearGradient(
          colors: [AppColors.ink, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  /// A flat equivalent of [selected], for places that fill rather than
  /// sweep — a tab indicator, say.
  static Color get selectedSolid =>
      AppColors.brightness == Brightness.dark ? AppColors.primary : AppColors.ink;

  /// Soft top-left light for dark surfaces. Layered OVER [ink] it stops
  /// the hero reading as a flat printed rectangle and gives it the sense
  /// of a light source, which is most of the "expensive" feeling.
  static const inkSheen = RadialGradient(
    center: Alignment(-0.7, -1.1),
    radius: 1.5,
    colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
  );
}

/// Font family names. Register `Inter` (body) and `Italiana` (display)
/// as assets in pubspec.yaml — see assets/fonts/README.
class AppFonts {
  AppFonts._();
  static const body = 'Inter';
  static const display = 'Italiana';
}

class AppTheme {
  AppTheme._();

  /// Built from whatever [AppColors.brightness] is currently set to, so
  /// one definition serves both themes. The structure — radii, spacing,
  /// type scale, button shapes — is identical either way; only the
  /// neutrals the tokens resolve to differ, which is the whole point of
  /// putting them behind getters.
  static ThemeData get current {
    return ThemeData(
      useMaterial3: true,
      brightness: AppColors.brightness,
      scaffoldBackgroundColor: AppColors.bgSoft,
      fontFamily: AppFonts.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: AppColors.brightness,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          color: AppColors.text,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }
}
