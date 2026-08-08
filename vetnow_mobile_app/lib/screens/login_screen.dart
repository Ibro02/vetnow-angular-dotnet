import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'register_screen.dart';

/// Mirrors frontend/src/app/pages/login/login.component.html
///
/// [isBookingGate] controls how this screen behaves when pushed:
/// - true  → pushed mid-booking-flow (guest checkout gate). On success,
///           pops with `true` so BookingScreen can continue.
/// - false → opened as a standalone route (e.g. from Profile tab). On
///           success, clears the stack back to the app root.
class LoginScreen extends StatefulWidget {
  final bool isBookingGate;

  const LoginScreen({super.key, this.isBookingGate = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _keepMeSignedIn = false;
  bool _isError = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final token = await AuthApiService.login(
        usernameOrEmail: _usernameOrEmailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      await AuthScope.of(context).loginWithToken(token, fallbackName: _usernameOrEmailController.text.trim());
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (widget.isBookingGate) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop();
      }
    } on NeedsVerificationException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = l10n.loginNeedsVerification;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.statusCode == 404 || e.statusCode == 400 ? l10n.loginInvalidCredentials : l10n.networkError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: widget.isBookingGate
          ? AppBar(
              backgroundColor: AppColors.bgSoft,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.text),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl2),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      widget.isBookingGate ? l10n.loginBookingGateTitle : l10n.loginTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (widget.isBookingGate) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        l10n.loginBookingGateSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s6),
                    AppTextField(
                      label: l10n.usernameOrEmail,
                      controller: _usernameOrEmailController,
                      isError: _isError,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    AppTextField(
                      label: l10n.password,
                      controller: _passwordController,
                      isPassword: true,
                      isError: _isError,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    if (_errorMessage != null) ...[
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
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                value: _keepMeSignedIn,
                                activeColor: AppColors.accent,
                                onChanged: (v) => setState(() => _keepMeSignedIn = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.keepSignedIn,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(l10n.forgotPassword, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    AppButton(
                      label: l10n.signIn,
                      onPressed: _signIn,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.noAccount,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RegisterScreen(isBookingGate: widget.isBookingGate)),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(l10n.register, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: AppColors.accent50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'VetNow',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
