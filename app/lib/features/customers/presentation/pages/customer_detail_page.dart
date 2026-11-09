import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../sales/domain/sale.dart';
import '../../../sales/presentation/pages/sale_form_page.dart' show kReturnSale;
import '../../../sales/domain/sale_summary.dart';
import '../../../sales/presentation/widgets/sale_list_items.dart';
import '../../data/customers_repository_impl.dart';
import '../../domain/customer.dart';

enum _MenuAction { toggleActive, delete }

/// Customer detail (03-AppFlow §6, PRD CUST-5/6/7): contact card with Call
/// and WhatsApp, totals (Purchases · Paid · Due), their sales (paginated),
/// Edit and ⋮ (Deactivate/Activate · Delete).
class CustomerDetailPage extends ConsumerStatefulWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  final _sales = PagedListController();
  Customer? _customer;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sales.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final c = await ref
          .read(customersRepositoryProvider)
          .get(widget.customerId);
      if (mounted) setState(() => _customer = c);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit() async {
    final updated = await context.push<Customer>(
      '/customers/${widget.customerId}/edit',
    );
    if (updated != null && mounted) setState(() => _customer = updated);
  }

  /// New sale with this customer selected → the saved sale.
  Future<void> _newSale() async {
    final sale = await context.push<Object?>(
      '/sales/new?customer=${widget.customerId}',
      extra: kReturnSale,
    );
    if (!mounted) return;
    _sales.refresh();
    unawaited(_load()); // fresh totals
    if (sale is Sale) await context.push('/sales/${sale.id}');
  }

  Future<void> _contact(Future<bool> Function(String) open) async {
    final ok = await open(_customer!.phone);
    if (!ok && mounted) showMessage(context, context.l10n.couldNotOpen);
  }

  Future<void> _onMenu(_MenuAction action) async {
    final c = _customer!;
    final l = context.l10n;
    final repo = ref.read(customersRepositoryProvider);
    switch (action) {
      case _MenuAction.toggleActive:
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
        if (!ok || !mounted) return;
        try {
          final (updated, message) = await repo.setActive(c.id, !deactivate);
          if (!mounted) return;
          setState(() => _customer = updated);
          showMessage(context, message);
        } on Failure catch (f) {
          if (mounted) showMessage(context, failureText(context, f));
        }
      case _MenuAction.delete:
        final ok = await showConfirmDialog(
          context,
          title: l.deleteCustomerTitle(c.name),
          message: l.deleteCustomerMessage,
          confirmLabel: l.delete,
          destructive: true,
        );
        if (!ok || !mounted) return;
        try {
          final message = await repo.delete(c.id);
          if (!mounted) return;
          showMessage(context, message);
          context.pop();
        } on Failure catch (f) {
          // 409: has sales → the server says to deactivate instead.
          if (mounted) showMessage(context, failureText(context, f));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _customer;
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? l.customerDetails),
        actions: [
          if (c != null) ...[
            IconButton(
              tooltip: l.edit,
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<_MenuAction>(
              tooltip: l.moreActions,
              onSelected: _onMenu,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _MenuAction.toggleActive,
                  child: ListTile(
                    leading: Icon(
                      c.isActive ? Icons.block : Icons.check_circle_outline,
                    ),
                    title: Text(c.isActive ? l.deactivate : l.activate),
                  ),
                ),
                PopupMenuItem(
                  value: _MenuAction.delete,
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: context.tokens.error,
                    ),
                    title: Text(
                      l.delete,
                      style: TextStyle(color: context.tokens.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: c == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const Center(child: CircularProgressIndicator()))
          : PagedList<SaleSummary>(
              controller: _sales,
              maxWidth: 960,
              fetch: (page) => ref
                  .read(customersRepositoryProvider)
                  .sales(widget.customerId, page: page),
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ContactCard(
                    customer: c,
                    onCall: () => _contact(ContactLauncher.call),
                    onWhatsApp: () => _contact(ContactLauncher.whatsApp),
                  ),
                  const SizedBox(height: Space.s3),
                  KpiRow(
                    children: [
                      KpiChip(
                        icon: Icons.shopping_bag_outlined,
                        label: l.purchases,
                        value: Fmt.money(c.totalSales),
                      ),
                      KpiChip(
                        icon: Icons.payments_outlined,
                        label: l.paid,
                        value: Fmt.money(c.totalPaid),
                        tint: KpiTint.green,
                      ),
                      KpiChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: l.due,
                        value: Fmt.money(c.totalDue),
                        tint: c.hasDue ? KpiTint.rose : KpiTint.sky,
                      ),
                    ],
                  ),
                  SectionHeader(
                    l.sales,
                    actionLabel: c.isActive ? l.newSale : null,
                    onAction: c.isActive ? _newSale : null,
                  ),
                ],
              ),
              empty: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l.noSalesYet,
                message: l.noSalesYetMessage,
              ),
              builder: (context, sales) => desktop
                  ? SalesTable(
                      sales: sales,
                      onOpen: (sale) => context.push('/sales/${sale.id}'),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in sales) ...[
                          SaleTile(
                            sale: s,
                            onTap: () => context.push('/sales/${s.id}'),
                          ),
                          const SizedBox(height: Space.s2),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.customer,
    required this.onCall,
    required this.onWhatsApp,
  });

  final Customer customer;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final c = customer;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(c.name, size: 56),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: AppTypography.h3.copyWith(color: t.textPrimary),
                    ),
                    SelectableText(
                      c.phone,
                      style: AppTypography.body.copyWith(
                        color: t.textSecondary,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    if (!c.isActive) ...[
                      const SizedBox(height: Space.s1),
                      StatusPill(l.inactive),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (c.address != null && c.address!.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 20, color: t.textTertiary),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: Text(
                    c.address!,
                    style: AppTypography.body.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.s4),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(l.call),
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(l.whatsApp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
