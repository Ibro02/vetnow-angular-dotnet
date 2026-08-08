import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/locale_state.dart';

/// Bottom sheet for picking the app language — reuses the same visual
/// language as the city picker on Explore (drag handle, close button,
/// gradient-highlighted selected row) for consistency.
void showLanguagePicker(BuildContext context) {
  final localeState = LocaleScope.of(context);
  final l10n = AppLocalizations.of(context)!;

  final options = <(String code, String label)>[
    ('bs', l10n.bosnian),
    ('hr', l10n.croatian),
    ('sr', l10n.serbian),
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s3, AppSpacing.s6, AppSpacing.s8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.chooseLanguage, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          ...options.map((opt) {
            final isSelected = localeState.locale.languageCode == opt.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: InkWell(
                onTap: () {
                  localeState.setLocale(Locale(opt.$1));
                  Navigator.of(sheetContext).pop();
                },
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]) : null,
                    color: isSelected ? null : AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.15) : AppColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.translate_rounded, size: 15, color: isSelected ? Colors.white : AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          opt.$2,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.text),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20)
                      else
                        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
