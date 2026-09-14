import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Heading above a group of notifications, with how many are in it.
class NotificationSectionLabel extends StatelessWidget {
  final String text;
  final int count;

  const NotificationSectionLabel({super.key, required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.text)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bgMuted,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// One row on the notifications screen.
///
/// Two shapes in one widget, because the difference is exactly one thing:
/// whether there is something to *do*. A row with [actionLabel] gets a
/// gold pill and becomes tappable; an informational row shows a quiet
/// [trailingNote] instead and doesn't pretend to be a button.
class NotificationTile extends StatelessWidget {
  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String? subtitle;

  /// Shown on the right of an informational row (e.g. the pet's name).
  final String? trailingNote;

  final String? actionLabel;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.icon,
    required this.iconGradient,
    required this.title,
    this.subtitle,
    this.trailingNote,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(gradient: iconGradient, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            )
          else if (trailingNote != null && trailingNote!.isNotEmpty)
            Text(
              trailingNote!,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: row,
    );
  }
}
