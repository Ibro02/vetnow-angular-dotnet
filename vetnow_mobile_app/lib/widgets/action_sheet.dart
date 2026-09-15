import 'package:flutter/material.dart';
import '../config/theme.dart';

class ActionSheetItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionSheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Premium replacement for PopupMenuButton's plain dropdown — same
/// bottom-sheet language as the city/language pickers (drag handle,
/// close button, icon-circle rows) instead of a bare Material menu.
void showActionSheet(BuildContext context, {String? title, required List<ActionSheetItem> items}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl2),
          topRight: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: AppSpacing.s5),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
          ),
          if (title != null) ...[
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
            const SizedBox(height: AppSpacing.s4),
          ],
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                child: InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    item.onTap();
                  },
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
                    decoration: BoxDecoration(
                      color: item.isDestructive ? AppColors.dangerSoft : AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(color: item.color.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: Icon(item.icon, size: 17, color: item.color),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Text(
                          item.label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: item.isDestructive ? AppColors.danger : AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    ),
  );
}
