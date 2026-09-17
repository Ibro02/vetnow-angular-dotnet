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

  /// Supplied when something outside the field needs to move focus
  /// here — a failed save scrolling to the first field it objects to.
  final FocusNode? focusNode;

  /// Fires on every keystroke. The screen uses it to clear this
  /// field's error the moment someone starts fixing it, rather than
  /// leaving it red until the next save.
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.isError = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.focusNode,
    this.onChanged,
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
        // Excluded, because the field below now carries the same
        // words as its accessible name. Left in, TalkBack reads
        // "Ime" and then "Ime, edit box" — the label twice, once
        // as a heading it cannot act on.
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // The field's name, which it did not have.
        //
        // The label is drawn as a separate Text above the box rather
        // than through InputDecoration, which looks right and reads as
        // nothing: a screen reader landing on the field announced
        // "edit box" with no indication of which one, on every form in
        // the app. The error, when there is one, is part of the name
        // too — it is the reason the field is worth returning to.
        Semantics(
          label: widget.errorText == null
              ? widget.label
              : '${widget.label}. ${widget.errorText}',
          textField: true,
          child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
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
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 5),
          // Icon as well as colour. Red alone carries the whole
          // message otherwise, and for a red-green colour blind
          // reader it carries none of it.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: AppColors.danger),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
