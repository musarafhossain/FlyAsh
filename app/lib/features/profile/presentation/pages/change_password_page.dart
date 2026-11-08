import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../auth/data/auth_repository_impl.dart';

/// My profile → Change password: current, new, confirm (PUT /auth/password).
/// Other devices are logged out; this one stays logged in.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage>
    with FormSubmit {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    late String message;
    final ok = await submit(() async {
      message = await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            password: _password.text,
            confirmation: _confirm.text,
          );
    });
    if (!ok || !mounted) return;
    showMessage(context, message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.changePassword)),
      body: Form(
        key: formKey,
        child: PageBody(
          children: [
            Text(
              l.changePasswordHint,
              style: AppTypography.body.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
            const SizedBox(height: Space.s4),
            PasswordField(
              controller: _current,
              label: l.currentPassword,
              validator: v.required,
              errorText: fieldErrors['current_password'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: Space.s3),
            PasswordField(
              controller: _password,
              label: l.newPassword,
              helperText: l.passwordRule,
              validator: v.password,
              errorText: fieldErrors['password'],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: Space.s3),
            PasswordField(
              controller: _confirm,
              label: l.confirmPassword,
              validator: v.sameAs(_password),
              errorText: fieldErrors['password_confirmation'],
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Space.s5),
            if (error != null) ...[
              FormErrorBanner(error!),
              const SizedBox(height: Space.s3),
            ],
            BusyButton(label: l.changePassword, busy: busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
