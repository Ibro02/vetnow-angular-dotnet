import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/vet_hero_background.dart';

/// Mirrors frontend/src/app/pages/register/register.component.html
///
/// Note: new accounts on this backend start unverified
/// (Person.Verified defaults to false), and there's no in-app email
/// verification flow yet — so after a successful register we don't
/// auto-login. We show a "check your email" message and send the
/// person back to Login instead.
class RegisterScreen extends StatefulWidget {
  final bool isBookingGate;

  const RegisterScreen({super.key, this.isBookingGate = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static final _passwordRule = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);

    if (_usernameController.text.trim().length < 5) {
      setState(() => _errorMessage = l10n.passwordRequirementsHint);
      return;
    }
    if (!_passwordRule.hasMatch(_passwordController.text)) {
      setState(() => _errorMessage = l10n.passwordRequirementsHint);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthApiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerSuccessCheckEmail)),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.ink,
            ),
            child: const VetHeroBackground(showPulse: false, showFloatingHearts: true),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s2, AppSpacing.s2, AppSpacing.s2, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          height: 34,
                          width: 34,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s2, AppSpacing.pagePadding, AppSpacing.s8),
                    child: Column(
                      children: [
                        Container(
                          height: 64,
                          width: 64,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.accent, blurRadius: 22, offset: Offset(0, 8)),
                              ],
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          l10n.createAccount,
                          style: const TextStyle(fontFamily: AppFonts.display, fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.registerSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl2 + 2),
                            gradient: LinearGradient(
                              colors: [AppColors.gold.withValues(alpha: 0.5), AppColors.accent.withValues(alpha: 0.4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 34, offset: const Offset(0, 18)),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.s6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.xl2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(label: l10n.firstName, controller: _firstNameController),
                                    ),
                                    const SizedBox(width: AppSpacing.s3),
                                    Expanded(
                                      child: AppTextField(label: l10n.lastName, controller: _lastNameController),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                AppTextField(
                                  label: l10n.email,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline,
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                AppTextField(
                                  label: l10n.username,
                                  controller: _usernameController,
                                  prefixIcon: Icons.person_outline,
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                AppTextField(
                                  label: l10n.password,
                                  controller: _passwordController,
                                  isPassword: true,
                                  prefixIcon: Icons.lock_outline,
                                ),
                                const SizedBox(height: 6),
                                Text(l10n.passwordRequirementsHint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: AppSpacing.s3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_errorMessage!, style: const TextStyle(fontSize: 12.5, color: AppColors.dangerHover)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.s6),
                                AppButton(
                                  label: l10n.createAccountButton,
                                  onPressed: _register,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(height: AppSpacing.s3),
                                AppButton(
                                  label: l10n.backToLogin,
                                  variant: AppButtonVariant.ghost,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
