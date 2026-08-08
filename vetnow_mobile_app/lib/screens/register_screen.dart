import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_app_bar.dart';

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
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.createAccount),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.createAccount, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(
                l10n.registerSubtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s6),
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
    );
  }
}
