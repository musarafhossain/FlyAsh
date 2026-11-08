import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/users_repository_impl.dart';

/// Add a user (name, phone, email, password) or edit one (no password).
/// Pops with the saved [AppUser].
class UserFormPage extends ConsumerStatefulWidget {
  const UserFormPage({super.key, this.userId, this.initial});

  /// Null = add a new user.
  final int? userId;

  /// The user when coming from the detail page (saves a request).
  final AppUser? initial;

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> with FormSubmit {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loaded = false;
  Object? _loadError;

  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) {
      _loaded = true;
    } else if (widget.initial != null) {
      _fill(widget.initial!);
    } else {
      _load();
    }
  }

  void _fill(AppUser u) {
    _name.text = u.name;
    _phone.text = u.phone;
    _email.text = u.email ?? '';
    _loaded = true;
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final user = await ref.read(usersRepositoryProvider).get(widget.userId!);
      if (mounted) setState(() => _fill(user));
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(usersRepositoryProvider);
    late AppUser saved;
    final ok = await submit(() async {
      saved = _isEdit
          ? await repo.update(
              widget.userId!,
              name: _name.text,
              phone: _phone.text,
              email: textOrNull(_email),
            )
          : await repo.create(
              name: _name.text,
              phone: _phone.text,
              email: textOrNull(_email),
              password: _password.text,
            );
    });
    if (!ok || !mounted) return;
    final l = context.l10n;
    showMessage(context, _isEdit ? l.userUpdated : l.userCreated);
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.editUser : l.addUser)),
      body: !_loaded
          ? (_loadError != null
                ? ErrorState(
                    message: failureText(context, _loadError!),
                    onRetry: _load,
                  )
                : const Center(child: CircularProgressIndicator()))
          : Form(
              key: formKey,
              child: PageBody(
                children: [
                  PersonFields(
                    name: _name,
                    phone: _phone,
                    email: _email,
                    errors: fieldErrors,
                    emailHelper: l.emailForgotHint,
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: Space.s3),
                    PasswordField(
                      controller: _password,
                      label: l.passwordField,
                      helperText: l.passwordRule,
                      validator: v.password,
                      errorText: fieldErrors['password'],
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _save(),
                    ),
                  ],
                  const SizedBox(height: Space.s5),
                  if (error != null) ...[
                    FormErrorBanner(error!),
                    const SizedBox(height: Space.s3),
                  ],
                  BusyButton(
                    label: _isEdit ? l.save : l.addUser,
                    busy: busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Name, phone (10 digits) and optional email inputs, used by the user
/// form and My profile → Edit.
class PersonFields extends StatelessWidget {
  const PersonFields({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.errors,
    this.emailHelper,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;

  /// Server field errors (`name`, `phone`, `email`).
  final Map<String, String> errors;
  final String? emailHelper;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          maxLength: 100,
          validator: v.required,
          decoration: InputDecoration(
            labelText: l.nameField,
            prefixIcon: const Icon(Icons.person_outline),
            errorText: errors['name'],
            counterText: '',
          ),
        ),
        const SizedBox(height: Space.s3),
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: v.phone,
          decoration: InputDecoration(
            labelText: l.phoneField,
            prefixIcon: const Icon(Icons.phone_outlined),
            errorText: errors['phone'],
          ),
        ),
        const SizedBox(height: Space.s3),
        TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: v.optionalEmail,
          decoration: InputDecoration(
            labelText: l.emailOptional,
            helperText: emailHelper,
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.mail_outline),
            errorText: errors['email'],
          ),
        ),
      ],
    );
  }
}
