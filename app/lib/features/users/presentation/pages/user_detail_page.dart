import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/users_repository_impl.dart';
import 'users_list_page.dart';

/// One user: details and actions Edit · Reset password · Deactivate/Activate.
class UserDetailPage extends ConsumerStatefulWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  AppUser? _user;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final user = await ref.read(usersRepositoryProvider).get(widget.userId);
      if (mounted) setState(() => _user = user);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit() async {
    final updated = await context.push<AppUser>(
      '/users/${widget.userId}/edit',
      extra: _user,
    );
    if (updated != null && mounted) setState(() => _user = updated);
  }

  Future<void> _toggleActive() async {
    final user = _user!;
    final l = context.l10n;
    final deactivate = user.isActive;
    final ok = await showConfirmDialog(
      context,
      title: deactivate
          ? l.deactivateUserTitle(user.name)
          : l.activateUserTitle(user.name),
      message: deactivate ? l.deactivateUserMessage : l.activateUserMessage,
      confirmLabel: deactivate ? l.deactivate : l.activate,
      destructive: deactivate,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final (updated, message) = await ref
          .read(usersRepositoryProvider)
          .setActive(user.id, !deactivate);
      if (!mounted) return;
      setState(() => _user = updated);
      showMessage(context, message);
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => ResetPasswordDialog(user: _user!),
    );
    if (message != null && mounted) showMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.name ?? l.userDetails),
        actions: [
          if (user != null)
            IconButton(
              tooltip: l.edit,
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: user == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const Center(child: CircularProgressIndicator()))
          : PageBody(
              maxWidth: 720,
              children: [
                _UserHeader(user: user),
                const SizedBox(height: Space.s4),
                AppCard(
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.phone_outlined,
                        label: l.phoneField,
                        value: user.phone,
                      ),
                      InfoRow(
                        icon: Icons.mail_outline,
                        label: l.emailField,
                        value: user.email ?? '—',
                      ),
                      InfoRow(
                        icon: Icons.schedule,
                        label: l.lastLoginColumn,
                        value: lastLoginText(context, user),
                      ),
                    ],
                  ),
                ),
                if (user.email == null) ...[
                  const SizedBox(height: Space.s2),
                  Text(
                    l.noEmailHintUser,
                    style: AppTypography.caption.copyWith(
                      color: context.tokens.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: Space.s4),
                MenuGroup(
                  children: [
                    MenuRow(
                      icon: Icons.edit_outlined,
                      title: l.editUser,
                      onTap: _edit,
                    ),
                    MenuRow(
                      icon: Icons.lock_reset,
                      title: l.resetPassword,
                      subtitle: l.resetUserPasswordHint,
                      onTap: _resetPassword,
                    ),
                    MenuRow(
                      icon: user.isActive
                          ? Icons.block
                          : Icons.check_circle_outline,
                      title: user.isActive ? l.deactivate : l.activate,
                      subtitle: user.isActive ? l.deactivateUserMessage : null,
                      color: user.isActive ? context.tokens.error : null,
                      onTap: _busy ? null : _toggleActive,
                      showChevron: false,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Avatar, name and status (also used on My profile).
class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return AppCard(
      child: Row(
        children: [
          InitialsAvatar(user.name, size: 56),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.h3.copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: Space.s1),
                StatusPill(
                  user.isActive ? l.active : l.inactive,
                  tone: user.isActive ? StatusTone.success : StatusTone.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// New password + confirm for another user. Pops with the server message.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  const ResetPasswordDialog({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog>
    with FormSubmit {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    late String message;
    final ok = await submit(() async {
      message = await ref
          .read(usersRepositoryProvider)
          .resetPassword(
            widget.user.id,
            password: _password.text,
            confirmation: _confirm.text,
          );
    });
    if (ok && mounted) Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);
    return AlertDialog(
      title: Text(l.resetPasswordFor(widget.user.name)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.resetUserPasswordHint,
                style: AppTypography.body.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
              const SizedBox(height: Space.s4),
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
              if (error != null) ...[
                const SizedBox(height: Space.s3),
                FormErrorBanner(error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        BusyButton(label: l.resetPassword, busy: busy, onPressed: _save),
      ],
    );
  }
}
