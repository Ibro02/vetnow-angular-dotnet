import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A premium confirmation dialog — icon in a soft-tinted circle, big
/// friendly title, plain-language message, and two pill buttons. Used
/// for logout, cancel-appointment, and any other "are you sure" moment
/// that deserves better than the default AlertDialog look.
Future<bool> showPremiumConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color accentColor,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s8, AppSpacing.s6, AppSpacing.s6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.18), accentColor.withValues(alpha: 0.08)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 30),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Expanded(
                  child: _DialogPillButton(
                    label: cancelLabel,
                    filled: false,
                    accentColor: accentColor,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: _DialogPillButton(
                    label: confirmLabel,
                    filled: true,
                    accentColor: isDangerous ? AppColors.danger : accentColor,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _DialogPillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final Color accentColor;
  final VoidCallback onTap;

  const _DialogPillButton({
    required this.label,
    required this.filled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(colors: [accentColor, Color.lerp(accentColor, Colors.black, 0.15)!])
              : null,
          color: filled ? null : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: filled ? null : Border.all(color: AppColors.border),
          boxShadow: filled
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
