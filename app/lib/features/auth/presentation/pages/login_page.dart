import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/form_fields.dart';
import '../auth_controller.dart';
import '../widgets/auth_layout.dart';

/// Login with phone or email + password (03-AppFlow §2.1).
/// On success the router moves to Home (or the page the user wanted).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_login.text, _password.text);
    } on ValidationFailure catch (f) {
      setState(() => _fieldErrors = f.fieldErrors);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sessionExpired = ref.watch(
      authControllerProvider.select((s) => s.sessionExpired),
    );
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l.fieldRequired : null;

    return AuthLayout(
      title: l.signIn,
      subtitle: l.welcomeBack,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sessionExpired && _error == null) ...[
              FormErrorBanner(l.sessionEnded),
              const SizedBox(height: Space.s4),
            ],
            TextFormField(
              controller: _login,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.telephoneNumber,
                AutofillHints.email,
              ],
              validator: required,
              decoration: InputDecoration(
                labelText: l.loginField,
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _fieldErrors['login'],
              ),
            ),
            const SizedBox(height: Space.s3),
            PasswordField(
              controller: _password,
              label: l.passwordField,
              validator: required,
              errorText: _fieldErrors['password'],
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(l.forgotPassword),
              ),
            ),
            if (_error != null) ...[
              FormErrorBanner(_error!),
              const SizedBox(height: Space.s3),
            ],
            BusyButton(label: l.signIn, busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
