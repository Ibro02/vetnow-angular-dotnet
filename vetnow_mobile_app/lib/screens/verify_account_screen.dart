import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';

/// Confirms the code emailed to a freshly registered account.
///
/// This closes a flow that previously dead-ended: registering left the
/// account unverified, logging in returned 401 "needs verification", and
/// the app had nothing to do with that — so a new person could never
/// actually get in.
///
/// On success the backend both marks the account verified and issues a
/// session token, so we sign the person in right here rather than
/// bouncing them back to the login form.
class VerifyAccountScreen extends StatefulWidget {
  final int userId;

  /// Shown under the title so the person knows which inbox to check.
  final String? emailOrUsername;

  /// Carried over from the login form's "keep me signed in" checkbox —
  /// verifying signs the person straight in, so their choice there has to
  /// follow them here rather than being silently dropped.
  final bool remember;

  const VerifyAccountScreen({
    super.key,
    required this.userId,
    this.emailOrUsername,
    this.remember = false,
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _code.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final token = await AuthApiService.verify(userId: widget.userId, code: code);
      if (!mounted) return;

      await AuthScope.of(context).loginWithToken(
        token,
        fallbackName: widget.emailOrUsername,
        remember: widget.remember,
      );
      if (!mounted) return;

      // `true` tells the login screen the session is live, so it can close
      // itself and let the caller continue wherever they were heading.
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.verifyAccountTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.s8,
          AppSpacing.pagePadding,
          AppSpacing.s10,
        ),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.primary),
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            l10n.verifyAccountHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            widget.emailOrUsername == null
                ? l10n.verifyAccountBody
                : l10n.verifyAccountBodyFor(widget.emailOrUsername!),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _code,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  // Codes are numeric; filtering here stops a stray space
                  // or letter from producing a confusing server rejection.
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 8, fontSize: 24),
                    filled: true,
                    fillColor: AppColors.bgMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: l10n.verifyAccountAction,
            icon: Icons.check_rounded,
            isLoading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            l10n.verifyAccountResendHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
