// ═══════════════════════════════════════════════════════════
// VetNow Design Tokens — Flutter port of frontend/src/styles/theme.css
// Single source of truth for colors, typography, spacing, radius.
// Keep this in sync with the Angular theme so both apps stay
// visually identical.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand ──────────────────────────────────────────────
  static const primary = Color(0xFF33B3AE);
  static const primaryLight = Color(0xFF5CCCC7);
  static const primaryDark = Color(0xFF28918D);
  static const primary50 = Color(0x1433B3AE); // ~8% opacity
  static const primary100 = Color(0x2633B3AE); // ~15% opacity

  static const accent = Color(0xFF3FCA93);
  static const accentHover = Color(0xFF35B882);
  static const accentActive = Color(0xFF2EA574);
  static const accent50 = Color(0x143FCA93);

  // ─── Neutrals ───────────────────────────────────────────
  static const bg = Color(0xFFFFFFFF);
  static const bgSoft = Color(0xFFFAF9F6);
  static const bgMuted = Color(0xFFF3F4F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFF9FAFB);

  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F0F0);

  static const text = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  // ─── Semantic ───────────────────────────────────────────
  static const danger = Color(0xFFEF4444);
  static const dangerHover = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const info = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);

  // ─── Legacy aliases (from tailwind.config.js) ────────────
  static const lightGreen = Color(0xFF3FCA93);
  static const turquoiseBlue = Color(0xFF33B3AE);
  static const secondary = Color(0xFF868686);
  static const beige = Color(0xFFFAF9F6);
  static const roseModified = Color(0xFFFFC3AE);
  static const lightGreenModified = Color(0xFFF1F6BE);

  // ─── Premium / marketplace accents ───────────────────────
  // Warm gold for ratings & "premium" touches — deliberately outside
  // the teal/green brand pair so 4.9★ actually pops on a card.
  static const gold = Color(0xFFE8A73C);
  static const goldSoft = Color(0xFFFDF3E2);

  // Deep ink used for the "serious vet" premium surfaces (hero,
  // verified badge) instead of pure brand teal, for more contrast.
  static const ink = Color(0xFF0F2E2C);
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

  static const card = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 25,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  // Softer, colored glow used under the hero / CTA — the "premium" touch.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
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

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgSoft,
      fontFamily: AppFonts.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
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
      appBarTheme: const AppBarTheme(
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
          side: const BorderSide(color: AppColors.border),
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
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }
}
