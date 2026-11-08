import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../users/presentation/pages/user_form_page.dart';

/// My profile → Edit: name, phone, email (PUT /auth/me).
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage>
    with FormSubmit {
  late final _name = TextEditingController(text: _user?.name);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _email = TextEditingController(text: _user?.email);

  AppUser? get _user => ref.read(authControllerProvider).user;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await submit(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .updateMe(
            name: _name.text,
            phone: _phone.text,
            email: textOrNull(_email),
          );
      ref.read(authControllerProvider.notifier).updateUser(user);
    });
    if (!ok || !mounted) return;
    showMessage(context, context.l10n.profileUpdated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: formKey,
        child: PageBody(
          children: [
            PersonFields(
              name: _name,
              phone: _phone,
              email: _email,
              errors: fieldErrors,
              emailHelper: l.emailForgotHintSelf,
            ),
            const SizedBox(height: Space.s5),
            if (error != null) ...[
              FormErrorBanner(error!),
              const SizedBox(height: Space.s3),
            ],
            BusyButton(label: l.save, busy: busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
