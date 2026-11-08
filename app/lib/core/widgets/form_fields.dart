import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Password input with a show/hide eye button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.helperText,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _hidden ? l.showPassword : l.hidePassword,
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

/// 6 boxes for an OTP. One hidden text field drives the boxes, so typing,
/// pasting and SMS/keyboard autofill all work. Calls [onCompleted] at 6 digits.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.errorText,
    this.length = 6,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final int length;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = widget.controller.text;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: context.l10n.otpLabel,
          textField: true,
          child: GestureDetector(
            onTap: _focus.requestFocus,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) const SizedBox(width: Space.s2),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: Radii.mdAll,
                            border: Border.all(
                              color: hasError
                                  ? t.error
                                  : (_focus.hasFocus &&
                                        i ==
                                            text.length.clamp(
                                              0,
                                              widget.length - 1,
                                            ))
                                  ? t.primary
                                  : t.border,
                              width: _focus.hasFocus && i == text.length
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Text(
                            i < text.length ? text[i] : '',
                            style: AppTypography.h2.copyWith(
                              color: t.textPrimary,
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // The real input, invisible, on top of the boxes.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      key: const Key('otp-input'),
                      controller: widget.controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: widget.length,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Space.s2),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: t.error),
          ),
        ],
      ],
    );
  }
}

/// Error message box shown above a form's submit button.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Space.s3),
      decoration: BoxDecoration(color: t.errorBg, borderRadius: Radii.mdAll),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: t.error, size: 20),
          const SizedBox(width: Space.s2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: t.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// A filled button that shows a spinner (same width) while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
