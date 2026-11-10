import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/action_menu.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/app_user.dart';
import '../data/users_repository_impl.dart';
import 'pages/user_detail_page.dart' show ResetPasswordDialog;

/// Long-press menu of a user row:
///   View · Edit | Reset password | Deactivate / Activate
Future<void> showUserMenu(
  BuildContext row,
  WidgetRef ref,
  AppUser u, {
  required VoidCallback onOpen,
}) {
  final l = row.l10n;
  return showActionMenu(
    row,
    groups: [
      [
        ActionMenuItem(
          icon: Icons.visibility_outlined,
          label: l.view,
          onSelected: onOpen,
        ),
        ActionMenuItem(
          icon: Icons.edit_outlined,
          label: l.edit,
          onSelected: () => row.push('/users/${u.id}/edit', extra: u),
        ),
      ],
      [
        ActionMenuItem(
          icon: Icons.lock_reset,
          label: l.resetPassword,
          onSelected: () async {
            final message = await showDialog<String>(
              context: row,
              builder: (_) => ResetPasswordDialog(user: u),
            );
            if (message != null && row.mounted) showMessage(row, message);
          },
        ),
      ],
      [
        ActionMenuItem(
          icon: u.isActive ? Icons.block : Icons.check_circle_outline,
          label: u.isActive ? l.deactivate : l.activate,
          onSelected: () => toggleUserActive(row, ref, u),
        ),
      ],
    ],
  );
}

/// Asks, then activates / deactivates. Returns the updated user or null.
Future<AppUser?> toggleUserActive(
  BuildContext context,
  WidgetRef ref,
  AppUser user,
) async {
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
  if (!ok || !context.mounted) return null;
  try {
    final (updated, message) = await ref
        .read(usersRepositoryProvider)
        .setActive(user.id, !deactivate);
    if (context.mounted) showMessage(context, message);
    return updated;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return null;
  }
}
