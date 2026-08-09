import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/vet_hero_background.dart';
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
      backgroundColor: AppColors.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(
              widget.isBookingGate ? Icons.close : Icons.arrow_back,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(widget.isBookingGate ? false : null),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.ink, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const VetHeroBackground(showPulse: false, showFloatingHearts: true),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.s8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BrandMark(),
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
                          padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s6, AppSpacing.s6, AppSpacing.s8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.xl2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.isBookingGate ? l10n.loginBookingGateTitle : l10n.loginTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                widget.isBookingGate ? l10n.loginBookingGateSubtitle : l10n.loginWelcomeSubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                              ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 76,
          width: 76,
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
                BoxShadow(color: AppColors.accent, blurRadius: 26, offset: Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        const Text(
          'VetNow',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Za tvog ljubimca, s ljubavlju 🐾',
          style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
