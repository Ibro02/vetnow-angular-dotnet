import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';

/// Mirrors frontend components/common/sign-in-input and components/common/input.
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final bool isError;
  final String? errorText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.isError = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          style: TextStyle(color: AppColors.text, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.textMuted)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    // Says what the tap will do, not what is on screen —
                    // an unnamed eye is the classic silent control.
                    tooltip: _obscure
                        ? AppLocalizations.of(context)!.a11yShowPassword
                        : AppLocalizations.of(context)!.a11yHidePassword,
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: widget.isError ? AppColors.danger : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: widget.isError ? AppColors.danger : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
