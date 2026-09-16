import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_button.dart';
import '../widgets/hero_shell.dart';
import '../widgets/vet_hero_background.dart';
import '../state/auth_state.dart';
import '../screens/login_screen.dart';

/// Shown inside a tab (Appointments / Profile) when the visitor is
/// browsing as a guest. Full-bleed dark gradient backdrop (same
/// language as the Explore hero — animated paw prints, glow orbs,
/// heartbeat pulse) with a floating card on top, gradient-bordered
/// like the login screen — so "you're not logged in yet" feels like a
/// deliberate premium moment instead of a bare error state.
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // The same layered ink surface as every header in the app: the
        // gradient, the paw texture, the top-left sheen, then a vignette
        // that darkens the corners so the card in the middle reads as lit.
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.ink),
          child: VetHeroBackground(),
        ),
        const IgnorePointer(
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
        ),
        const HeroVignette(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl2 + 2),
                  gradient: LinearGradient(
                    colors: [AppColors.gold.withValues(alpha: 0.4), AppColors.primary.withValues(alpha: 0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 16)),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 88,
                        width: 88,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primary, blurRadius: 20, offset: Offset(0, 8)),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 38),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s5),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.text),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      ),
                      // Only when the session ended on its own.
                      //
                      // Being returned to a sign-in screen you did not
                      // ask for reads as the app having lost your
                      // account. One line is the difference between that
                      // and "your session ran out, sign in again".
                      if (AuthScope.of(context).sessionExpired) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 16, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context)!.sessionExpired,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (benefits.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s6),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s4),
                          decoration: BoxDecoration(
                            color: AppColors.bgSoft,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: benefits
                                .map(
                                  (b) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 20,
                                          margin: const EdgeInsets.only(top: 1),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 13, color: Colors.white),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(b, style: TextStyle(fontSize: 13.5, color: AppColors.text, height: 1.3)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 13, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!.takesLessThanMinute,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
