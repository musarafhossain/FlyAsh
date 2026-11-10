import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/session.dart';
import '../../../core/widgets/action_menu.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/state_views.dart';
import '../data/sales_repository_impl.dart';
import '../domain/sale.dart';
import '../domain/sale_summary.dart';
import 'widgets/sale_action_sheets.dart';

/// The long-press menu of a sale row (sales list, deliveries, a customer's
/// sales, the dashboard), with only the actions that sale allows:
///   View · Edit | Add payment · Mark delivered | Cancel booking | Delete
/// Lists reload by themselves after a change (`dataChangedProvider`).
Future<void> showSaleMenu(
  BuildContext row,
  WidgetRef ref,
  SaleSummary s, {
  required VoidCallback onOpen,
}) {
  final l = row.l10n;
  final canPay = !s.isCancelled && !Sale.isZeroAmount(s.dueAmount);
  final booked = s.status == 'booked';
  return showActionMenu(
    row,
    groups: [
      [
        ActionMenuItem(
          icon: Icons.visibility_outlined,
          label: l.view,
          onSelected: onOpen,
        ),
        if (!s.isCancelled)
          ActionMenuItem(
            icon: Icons.edit_outlined,
            label: l.edit,
            onSelected: () => row.push('/sales/${s.id}/edit'),
          ),
      ],
      [
        if (canPay)
          ActionMenuItem(
            icon: Icons.add_card,
            label: l.addPayment,
            onSelected: () => _addPayment(row, ref, s),
          ),
        if (booked)
          ActionMenuItem(
            icon: Icons.local_shipping_outlined,
            label: l.markDelivered,
            onSelected: () => _deliver(row, ref, s),
          ),
      ],
      [
        if (booked)
          ActionMenuItem(
            icon: Icons.cancel_outlined,
            label: l.cancelBooking,
            onSelected: () => _cancel(row, ref, s),
          ),
      ],
      [
        ActionMenuItem(
          icon: Icons.delete_outline,
          label: l.delete,
          destructive: true,
          onSelected: () => _delete(row, ref, s),
        ),
      ],
    ],
  );
}

/// Runs a sale action and shows the server's message (or the error).
Future<void> _run(
  BuildContext context,
  Future<String> Function() action,
) async {
  try {
    final message = await action();
    if (context.mounted) showMessage(context, message);
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
  }
}

Future<void> _addPayment(
  BuildContext context,
  WidgetRef ref,
  SaleSummary s,
) async {
  final repo = ref.read(salesRepositoryProvider);
  final Sale sale;
  try {
    sale = await repo.get(s.id); // the sheet shows the due and payments
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return;
  }
  if (!context.mounted) return;
  final input = await showAddPaymentSheet(
    context,
    sale: sale,
    today: ref.read(businessDateProvider),
  );
  if (input == null || !context.mounted) return;
  await _run(context, () async => (await repo.addPayment(s.id, input)).$2);
}

Future<void> _deliver(
  BuildContext context,
  WidgetRef ref,
  SaleSummary s,
) async {
  final date = await showDeliverSheet(
    context,
    invoiceNo: s.invoiceNo,
    saleDate: s.saleDate,
    today: ref.read(businessDateProvider),
  );
  if (date == null || !context.mounted) return;
  await _run(
    context,
    () async =>
        (await ref
                .read(salesRepositoryProvider)
                .deliver(s.id, deliveredDate: date))
            .$2,
  );
}

Future<void> _cancel(BuildContext context, WidgetRef ref, SaleSummary s) async {
  final l = context.l10n;
  final repo = ref.read(salesRepositoryProvider);
  final Sale sale;
  try {
    sale = await repo.get(s.id);
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return;
  }
  if (!context.mounted) return;
  if (sale.payments.isNotEmpty) {
    // The server refuses too; explain instead of asking.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.cancelBooking),
        content: Text(l.removePaymentsFirst),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    return;
  }
  final ok = await showConfirmDialog(
    context,
    title: l.cancelBookingTitle(s.invoiceNo),
    message: l.cancelBookingMessage,
    confirmLabel: l.cancelBooking,
    cancelLabel: l.keepBooking,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await _run(context, () async => (await repo.cancel(s.id)).$2);
}

Future<void> _delete(BuildContext context, WidgetRef ref, SaleSummary s) async {
  final l = context.l10n;
  final ok = await showConfirmDialog(
    context,
    title: l.deleteSaleTitle(s.invoiceNo),
    message: l.deleteSaleMessage,
    confirmLabel: l.delete,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await _run(context, () => ref.read(salesRepositoryProvider).delete(s.id));
}
