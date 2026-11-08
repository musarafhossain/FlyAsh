import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/auth_repository_impl.dart';
import '../widgets/auth_layout.dart';

/// Replaces any visible snackbar (messages must not queue up behind each other).
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// ① Email → the server emails a 6-digit OTP (03-AppFlow §2.2).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _fieldError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldError = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      final message = await ref
          .read(authRepositoryProvider)
          .forgotPassword(email);
      if (!mounted) return;
      showMessage(context, message);
      unawaited(context.push('/forgot-password/verify', extra: email));
    } on ValidationFailure catch (f) {
      setState(() => _fieldError = f['email']);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return AuthLayout(
      title: l.forgotTitle,
      subtitle: l.forgotHint,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => looksLikeEmail(v ?? '') ? null : l.invalidEmail,
              decoration: InputDecoration(
                labelText: l.emailField,
                prefixIcon: const Icon(Icons.mail_outline),
                errorText: _fieldError,
              ),
            ),
            const SizedBox(height: Space.s4),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: Space.s3),
            ],
            BusyButton(label: l.sendOtp, busy: _busy, onPressed: _submit),
            const SizedBox(height: Space.s4),
            Text(
              l.noEmailHint,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// ② Verify the OTP → signed reset token (10 min, single use).
class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  static const _resendSeconds = 60;
  final _otp = TextEditingController();
  bool _busy = false;
  String? _error;
  int _wait = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _wait = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_wait <= 1) timer.cancel();
      if (mounted) setState(() => _wait--);
    });
  }

  Future<void> _verify([String? _]) async {
    if (_busy || _otp.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: widget.email, otp: _otp.text);
      if (!mounted) return;
      context.pushReplacement('/forgot-password/reset', extra: token);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(
        () => _error = f is ValidationFailure
            ? (f['otp'] ?? f.message)
            : failureText(context, f),
      );
      _otp.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .forgotPassword(widget.email);
      if (!mounted) return;
      showMessage(context, message);
      setState(() => _error = null);
      _startTimer();
    } on Failure catch (f) {
      if (mounted) setState(() => _error = failureText(context, f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthLayout(
      title: l.verifyTitle,
      subtitle: l.otpSentTo(_maskEmail(widget.email)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OtpField(controller: _otp, onCompleted: _verify, errorText: _error),
          const SizedBox(height: Space.s4),
          BusyButton(
            label: l.verify,
            busy: _busy,
            onPressed: _otp.text.length == 6 ? _verify : null,
          ),
          const SizedBox(height: Space.s2),
          Center(
            child: _wait > 0
                ? Padding(
                    padding: const EdgeInsets.all(Space.s3),
                    child: Text(
                      l.resendIn('$_wait'),
                      style: AppTypography.caption.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  )
                : TextButton(onPressed: _resend, child: Text(l.resendOtp)),
          ),
        ],
      ),
    );
  }
}

/// r•••@gmail.com
String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return email;
  return '${email[0]}•••${email.substring(at)}';
}

/// ③ Set the new password with the reset token.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.resetToken});

  final String resetToken;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .resetPassword(
            resetToken: widget.resetToken,
            password: _password.text,
            confirmation: _confirm.text,
          );
      if (!mounted) return;
      showMessage(context, message);
      context.go('/login');
    } on ValidationFailure catch (f) {
      setState(() => _fieldErrors = f.fieldErrors);
    } on Failure catch (f) {
      if (!mounted) return;
      // Expired / used token: start again.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.resetTitle),
          content: Text(failureText(context, f)),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/forgot-password');
              },
              child: Text(context.l10n.startAgain),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmLeave() => showConfirmDialog(
    context,
    title: context.l10n.cancelResetTitle,
    message: context.l10n.cancelResetMessage,
    confirmLabel: context.l10n.leave,
    cancelLabel: context.l10n.keepGoing,
    destructive: true,
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) context.go('/login');
      },
      child: AuthLayout(
        title: l.resetTitle,
        showLogo: false,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _password,
                label: l.newPassword,
                helperText: l.passwordRule,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _fieldErrors['password'],
                validator: (v) => (v ?? '').length < 6 ? l.passwordRule : null,
              ),
              const SizedBox(height: Space.s3),
              PasswordField(
                controller: _confirm,
                label: l.confirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _fieldErrors['password_confirmation'],
                validator: (v) =>
                    v != _password.text ? l.passwordsDontMatch : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.s4),
              BusyButton(
                label: l.resetPassword,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
