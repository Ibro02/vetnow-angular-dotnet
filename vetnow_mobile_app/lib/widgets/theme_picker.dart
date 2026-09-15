import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../state/theme_state.dart';

/// Light, dark, or follow the phone.
///
/// "Follow the phone" is listed first and is the default, because it is
/// what most people actually want — and because an app that ignores a
/// system-wide dark setting is the one bright rectangle at midnight.
Future<void> showThemePicker(BuildContext context) {
  final themeState = ThemeScope.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ThemeSheet(state: themeState),
  );
}

class _ThemeSheet extends StatelessWidget {
  final ThemeState state;

  const _ThemeSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_rounded),
      (ThemeMode.light, l10n.themeLight, Icons.light_mode_rounded),
      (ThemeMode.dark, l10n.themeDark, Icons.dark_mode_rounded),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s3,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
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
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.chooseTheme,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text),
              ),
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).closeButtonLabel,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                    child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          ...options.map((option) {
            final (mode, label, icon) = option;
            final selected = state.mode == mode;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: Semantics(
                button: true,
                selected: selected,
                inMutuallyExclusiveGroup: true,
                label: label,
                child: InkWell(
                  onTap: () {
                    Haptics.select();
                    state.set(mode);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  // The row's label is already on the Semantics node above.
                  // Left in, the Text underneath merges into it and every
                  // option is announced twice — "Dark, Dark".
                  child: ExcludeSemantics(
                      child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4,
                        vertical: AppSpacing.s3,
                      ),
                      decoration: BoxDecoration(
                        // AppGradients.selected, not ink: on the dark sheet
                        // an ink row is the sheet, so "Dark" — the row someone
                        // in dark mode is looking at — would be the one with
                        // no visible selection at all.
                        gradient: selected ? AppGradients.selected : null,
                        color: selected ? null : AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppColors.primary50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 16,
                              color: selected ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.text,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20)
                          else
                            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
