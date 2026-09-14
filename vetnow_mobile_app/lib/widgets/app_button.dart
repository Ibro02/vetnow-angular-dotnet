import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'paw_loader.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// The app's single button component — every screen routes through
/// this so a style change here updates everywhere at once. Primary and
/// danger use a soft gradient + glow shadow to match the premium
/// pill-button language used in dialogs and booking; secondary/ghost
/// stay flat and quiet since they're meant to recede.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  bool get _disabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? PawLoader(
            size: 20,
            color: variant == AppButtonVariant.secondary || variant == AppButtonVariant.ghost
                ? AppColors.primary
                : Colors.white,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => _GradientButton(
          colors: const [AppColors.accent, AppColors.accentHover],
          glowColor: AppColors.accent,
          onTap: isLoading ? null : onPressed,
          disabled: _disabled,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: IconTheme(data: const IconThemeData(color: Colors.white), child: child),
          ),
        ),
      AppButtonVariant.danger => _GradientButton(
          colors: const [AppColors.danger, AppColors.dangerHover],
          glowColor: AppColors.danger,
          onTap: isLoading ? null : onPressed,
          disabled: _disabled,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: IconTheme(data: const IconThemeData(color: Colors.white), child: child),
          ),
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _GradientButton extends StatelessWidget {
  final List<Color> colors;
  final Color glowColor;
  final VoidCallback? onTap;
  final bool disabled;
  final Widget child;

  const _GradientButton({
    required this.colors,
    required this.glowColor,
    required this.onTap,
    required this.disabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: disabled ? null : LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            color: disabled ? AppColors.border : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            // A brighter hairline along the top edge reads as a highlight
            // catching the light, which is what separates a "button with a
            // gradient" from a button that looks physically raised.
            border: disabled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.8),
            boxShadow: disabled ? null : AppShadows.glow(glowColor),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
