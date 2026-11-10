import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/session.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/widgets/action_menu.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/state_views.dart';
import '../data/labours_repository_impl.dart';
import '../domain/labour.dart';
import 'pages/labour_detail_page.dart' show LeavingDateDialog;

/// Long-press menu of a labour row:
///   View · Edit | Call (when there is a phone) | Deactivate / Activate
Future<void> showLabourMenu(
  BuildContext row,
  WidgetRef ref,
  Labour lb, {
  required VoidCallback onOpen,
}) {
  final l = row.l10n;
  final phone = lb.phone ?? '';
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
          onSelected: () => row.push('/labours/${lb.id}/edit'),
        ),
      ],
      [
        if (phone.isNotEmpty)
          ActionMenuItem(
            icon: Icons.call_outlined,
            label: l.call,
            onSelected: () async {
              final ok = await ContactLauncher.call(phone);
              if (!ok && row.mounted) showMessage(row, l.couldNotOpen);
            },
          ),
      ],
      [
        ActionMenuItem(
          icon: lb.isActive ? Icons.block : Icons.check_circle_outline,
          label: lb.isActive ? l.deactivate : l.activate,
          onSelected: () => toggleLabourActive(row, ref, lb),
        ),
      ],
    ],
  );
}

/// Deactivating asks for the leaving date; activating asks to confirm.
/// Returns the updated labour, or null when cancelled or refused.
Future<Labour?> toggleLabourActive(
  BuildContext context,
  WidgetRef ref,
  Labour lb,
) async {
  final l = context.l10n;
  String? leftDate;
  if (lb.isActive) {
    leftDate = await showDialog<String>(
      context: context,
      builder: (_) =>
          LeavingDateDialog(labour: lb, today: ref.read(businessDateProvider)),
    );
    if (leftDate == null) return null;
  } else {
    final ok = await showConfirmDialog(
      context,
      title: l.activateLabourTitle(lb.name),
      message: l.activateLabourMessage,
      confirmLabel: l.activate,
    );
    if (!ok) return null;
  }
  if (!context.mounted) return null;
  try {
    final (updated, message) = await ref
        .read(laboursRepositoryProvider)
        .setActive(lb.id, !lb.isActive, leftDate: leftDate);
    if (context.mounted) showMessage(context, message);
    return updated;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return null;
  }
}
