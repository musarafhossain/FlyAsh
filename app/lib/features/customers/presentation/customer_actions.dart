import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/widgets/action_menu.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/state_views.dart';
import '../data/customers_repository_impl.dart';
import '../domain/customer.dart';

/// Long-press menu of a customer row:
///   View · Edit | Call · WhatsApp | Deactivate / Activate | Delete
Future<void> showCustomerMenu(
  BuildContext row,
  WidgetRef ref,
  Customer c, {
  required VoidCallback onOpen,
}) {
  final l = row.l10n;
  Future<void> contact(Future<bool> Function(String) open) async {
    final ok = await open(c.phone);
    if (!ok && row.mounted) showMessage(row, l.couldNotOpen);
  }

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
          onSelected: () => row.push('/customers/${c.id}/edit'),
        ),
      ],
      [
        if (c.hasPhone) ...[
          ActionMenuItem(
            icon: Icons.call_outlined,
            label: l.call,
            onSelected: () => contact(ContactLauncher.call),
          ),
          ActionMenuItem(
            icon: Icons.chat_outlined,
            label: l.whatsApp,
            onSelected: () => contact(ContactLauncher.whatsApp),
          ),
        ],
      ],
      [
        ActionMenuItem(
          icon: c.isActive ? Icons.block : Icons.check_circle_outline,
          label: c.isActive ? l.deactivate : l.activate,
          onSelected: () => toggleCustomerActive(row, ref, c),
        ),
      ],
      [
        ActionMenuItem(
          icon: Icons.delete_outline,
          label: l.delete,
          destructive: true,
          onSelected: () => deleteCustomer(row, ref, c),
        ),
      ],
    ],
  );
}

/// Asks, then activates / deactivates. Returns the updated customer, or
/// null when cancelled or refused.
Future<Customer?> toggleCustomerActive(
  BuildContext context,
  WidgetRef ref,
  Customer c,
) async {
  final l = context.l10n;
  final deactivate = c.isActive;
  final ok = await showConfirmDialog(
    context,
    title: deactivate
        ? l.deactivateCustomerTitle(c.name)
        : l.activateCustomerTitle(c.name),
    message: deactivate
        ? l.deactivateCustomerMessage
        : l.activateCustomerMessage,
    confirmLabel: deactivate ? l.deactivate : l.activate,
    destructive: deactivate,
  );
  if (!ok || !context.mounted) return null;
  try {
    final (updated, message) = await ref
        .read(customersRepositoryProvider)
        .setActive(c.id, !deactivate);
    if (context.mounted) showMessage(context, message);
    return updated;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return null;
  }
}

/// Asks, then deletes. True when deleted. A customer with sales is refused
/// (409) and the server's message says to deactivate instead.
Future<bool> deleteCustomer(
  BuildContext context,
  WidgetRef ref,
  Customer c,
) async {
  final l = context.l10n;
  final ok = await showConfirmDialog(
    context,
    title: l.deleteCustomerTitle(c.name),
    message: l.deleteCustomerMessage,
    confirmLabel: l.delete,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    final message = await ref.read(customersRepositoryProvider).delete(c.id);
    if (context.mounted) showMessage(context, message);
    return true;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return false;
  }
}
