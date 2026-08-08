import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_button.dart';
import '../screens/login_screen.dart';

/// Shown inside a tab (Appointments / Profile) when the visitor is
/// browsing as a guest. Designed to feel calm and premium rather than
/// like a hard paywall — big icon, plain-language benefits, one clear
/// button. Kept deliberately simple (large text, high contrast, a
/// single obvious action) since this app is used by people of very
/// different ages and comfort levels with apps.
class AuthPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<String> benefits;

  const AuthPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.benefits = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              boxShadow: AppShadows.elevated,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 84,
                  width: 84,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 38),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19, color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: benefits
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, size: 13, color: AppColors.success),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(b, style: const TextStyle(fontSize: 13.5, color: AppColors.text)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                AppButton(
                  label: AppLocalizations.of(context)!.logInRegister,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  AppLocalizations.of(context)!.takesLessThanMinute,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
