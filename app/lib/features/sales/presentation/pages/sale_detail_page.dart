import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../products/presentation/pages/products_list_page.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale.dart';
import '../sale_labels.dart';
import '../widgets/sale_action_sheets.dart';
import '../../../../core/widgets/skeletons.dart';

/// Sale detail (04-UI-UX "Sale detail"): invoice no. and status pills →
/// customer card (Call / WhatsApp, opens the customer) → items → money
/// summary (subtotal, transport, discount, total, cost, profit, paid, due)
/// → payments. Actions (03-AppFlow §5.2): Add payment · Mark delivered ·
/// Cancel booking (buttons), Edit and Delete (app bar), delete a payment
/// (⋮ on its row). Share receipt comes in F17.
class SaleDetailPage extends ConsumerStatefulWidget {
  const SaleDetailPage({super.key, required this.saleId});

  final String saleId;

  @override
  ConsumerState<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends ConsumerState<SaleDetailPage> {
  Sale? _sale;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _busy = false;

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final sale = await ref.read(salesRepositoryProvider).get(widget.saleId);
      if (mounted) setState(() => _sale = sale);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Runs an action that returns the updated sale; shows its message.
  Future<void> _run(Future<(Sale, String)> Function() action) async {
    setState(() => _busy = true);
    try {
      final (sale, message) = await action();
      if (!mounted) return;
      setState(() => _sale = sale);
      showMessage(context, message);
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _today => ref.read(businessDateProvider);

  Future<void> _addPayment() async {
    final input = await showAddPaymentSheet(
      context,
      sale: _sale!,
      today: _today,
    );
    if (input == null || !mounted) return;
    await _run(
      () => ref.read(salesRepositoryProvider).addPayment(widget.saleId, input),
    );
  }

  Future<void> _deletePayment(SalePayment p) async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.deletePaymentTitle(Fmt.money(p.amount, decimals: true)),
      message: l.deletePaymentMessage,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(
      () =>
          ref.read(salesRepositoryProvider).deletePayment(widget.saleId, p.id),
    );
  }

  Future<void> _deliver() async {
    final s = _sale!.summary;
    final date = await showDeliverSheet(
      context,
      invoiceNo: s.invoiceNo,
      saleDate: s.saleDate,
      today: _today,
    );
    if (date == null || !mounted) return;
    await _run(
      () => ref
          .read(salesRepositoryProvider)
          .deliver(widget.saleId, deliveredDate: date),
    );
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final sale = _sale!;
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
      title: l.cancelBookingTitle(sale.summary.invoiceNo),
      message: l.cancelBookingMessage,
      confirmLabel: l.cancelBooking,
      cancelLabel: l.keepBooking,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() => ref.read(salesRepositoryProvider).cancel(widget.saleId));
  }

  Future<void> _edit() async {
    final updated = await context.push<Sale>('/sales/${widget.saleId}/edit');
    if (updated != null && mounted) setState(() => _sale = updated);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.deleteSaleTitle(_sale!.summary.invoiceNo),
      message: l.deleteSaleMessage,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final message = await ref
          .read(salesRepositoryProvider)
          .delete(widget.saleId);
      if (!mounted) return;
      showMessage(context, message);
      context.pop();
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sale = _sale;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    return Scaffold(
      appBar: AppBar(
        title: Text(sale?.summary.invoiceNo ?? l.saleDetails),
        actions: [
          if (sale != null && !sale.summary.isCancelled)
            IconButton(
              tooltip: l.edit,
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (sale != null)
            ActionMenuButton(
              tooltip: l.moreActions,
              enabled: !_busy,
              groups: [
                [
                  if (!sale.summary.isCancelled &&
                      !Sale.isZeroAmount(sale.summary.dueAmount))
                    ActionMenuItem(
                      icon: Icons.add_card,
                      label: l.addPayment,
                      onSelected: _addPayment,
                    ),
                  if (sale.summary.status == 'booked')
                    ActionMenuItem(
                      icon: Icons.local_shipping_outlined,
                      label: l.markDelivered,
                      onSelected: _deliver,
                    ),
                ],
                [
                  if (sale.summary.status == 'booked')
                    ActionMenuItem(
                      icon: Icons.cancel_outlined,
                      label: l.cancelBooking,
                      onSelected: _cancel,
                    ),
                ],
                [
                  ActionMenuItem(
                    icon: Icons.delete_outline,
                    label: l.deleteSale,
                    destructive: true,
                    onSelected: _delete,
                  ),
                ],
              ],
            ),
        ],
      ),
      body: sale == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const SaleDetailSkeleton())
          : RefreshIndicator(
              onRefresh: _load,
              child: wide ? _wide(sale) : _narrow(sale),
            ),
    );
  }

  /// Phone/tablet: one column.
  Widget _narrow(Sale sale) => PageBody(
    maxWidth: 720,
    children: [
      _Header(sale: sale),
      const SizedBox(height: Space.s3),
      _CustomerCard(sale: sale),
      const SizedBox(height: Space.s3),
      _Items(sale: sale),
      const SizedBox(height: Space.s3),
      _Summary(sale: sale),
      const SizedBox(height: Space.s3),
      _Payments(sale: sale, onDelete: _busy ? null : _deletePayment),
    ],
  );

  /// Desktop: items and payments on the left, header, customer and money
  /// summary on the right.
  Widget _wide(Sale sale) => PageBody(
    maxWidth: 1200,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(sale: sale),
                const SizedBox(height: Space.s3),
                _Items(sale: sale),
                const SizedBox(height: Space.s3),
                _Payments(sale: sale, onDelete: _busy ? null : _deletePayment),
              ],
            ),
          ),
          const SizedBox(width: Space.s4),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CustomerCard(sale: sale),
                const SizedBox(height: Space.s3),
                _Summary(sale: sale),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final s = sale.summary;
    final booked = s.status == 'booked';

    String line(String label, String? ymd) => '$label: ${Fmt.date(ymd)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                s.invoiceNo,
                style: AppTypography.h2.copyWith(color: t.textPrimary),
              ),
              StatusPill(l.saleTypeText(s.type), tone: StatusTone.info),
              if (s.isCancelled)
                StatusPill(l.saleCancelled)
              else ...[
                StatusPill(
                  l.saleStatusText(s.status),
                  tone: booked ? StatusTone.info : StatusTone.success,
                ),
                StatusPill(
                  l.paymentStatusText(s.paymentStatus),
                  tone: StatusPill.toneFor(s.paymentStatus),
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.s3),
          _Meta(icon: Icons.event, text: line(l.saleDate, s.saleDate)),
          if (s.type == 'booking' && s.deliveryDate != null)
            _Meta(
              icon: Icons.local_shipping_outlined,
              text: line(l.deliveryDate, s.deliveryDate),
            ),
          if (sale.deliveredDate != null && s.type == 'booking')
            _Meta(
              icon: Icons.check_circle_outline,
              text: line(l.deliveredOn, sale.deliveredDate),
            ),
          if (sale.deliveryAddress != null && sale.deliveryAddress!.isNotEmpty)
            _Meta(icon: Icons.place_outlined, text: sale.deliveryAddress!),
          if (sale.notes != null && sale.notes!.isNotEmpty)
            _Meta(icon: Icons.sticky_note_2_outlined, text: sale.notes!),
          if (sale.createdBy != null)
            _Meta(
              icon: Icons.person_outline,
              text: l.createdBy(sale.createdBy!),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: Space.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: t.textTertiary),
          const SizedBox(width: Space.s2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.sale});

  final Sale sale;

  Future<void> _contact(
    BuildContext context,
    Future<bool> Function(String) open,
  ) async {
    final ok = await open(sale.summary.customerPhone ?? '');
    if (!ok && context.mounted) {
      showMessage(context, context.l10n.couldNotOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final s = sale.summary;
    final name = s.customerName ?? '—';
    return AppCard(
      onTap: s.customerId == null
          ? null
          : () => context.push('/customers/${s.customerId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(name),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.title.copyWith(color: t.textPrimary),
                    ),
                    if (s.customerPhone != null)
                      Text(
                        s.customerPhone!,
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    if (sale.customerAddress != null &&
                        sale.customerAddress!.isNotEmpty)
                      Text(
                        sale.customerAddress!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.textTertiary),
            ],
          ),
          if (s.customerPhone != null) ...[
            const SizedBox(height: Space.s3),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _contact(context, ContactLauncher.call),
                    icon: const Icon(Icons.call_outlined),
                    label: Text(l.call),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _contact(context, ContactLauncher.whatsApp),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l.whatsApp),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DetailSection(
      title: l.itemsCount('${sale.items.length}'),
      children: [
        for (final item in sale.items)
          DetailRow(
            leading: ProductIcon(seed: item.productName, size: 44),
            title: item.productName,
            subtitle:
                '${Fmt.count(item.quantity)} × '
                '${Fmt.money(item.unitPrice, decimals: true)} '
                '${l.perUnit(unitText(l, item.unit))}',
            amount: Fmt.money(item.lineTotal),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final s = sale.summary;
    final dueZero = Sale.isZeroAmount(s.dueAmount);
    String money(String v) => Fmt.money(v, decimals: true);

    return LineItemSummaryCard(
      title: l.amountSummary,
      lines: [
        SummaryLine(l.subtotal, money(sale.subtotal)),
        if (!Sale.isZeroAmount(sale.transportCharge))
          SummaryLine(l.transport, '+ ${money(sale.transportCharge)}'),
        if (!Sale.isZeroAmount(sale.discount))
          SummaryLine(l.discount, '− ${money(sale.discount)}'),
        if (!Sale.isZeroAmount(sale.taxAmount))
          SummaryLine(
            l.taxLine(
              (Decimal.tryParse(sale.taxPercent) ?? Decimal.zero).toString(),
            ),
            '+ ${money(sale.taxAmount)}',
          ),
        SummaryLine(
          l.total,
          money(s.total),
          emphasis: true,
          dividerBefore: true,
        ),
        SummaryLine(l.productionCost, money(sale.totalCost)),
        SummaryLine(
          l.profit,
          money(sale.profit),
          color: sale.profit.startsWith('-') ? t.error : t.success,
        ),
        SummaryLine(
          l.paid,
          money(s.paidAmount),
          dividerBefore: true,
          color: t.success,
        ),
        SummaryLine(
          l.due,
          money(s.dueAmount),
          emphasis: true,
          color: dueZero || s.isCancelled ? t.textTertiary : t.error,
        ),
      ],
    );
  }
}

class _Payments extends StatelessWidget {
  const _Payments({required this.sale, this.onDelete});

  final Sale sale;

  /// Long press → Delete on each payment (null while an action runs).
  final ValueChanged<SalePayment>? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return DetailSection(
      title: l.paymentsCount('${sale.payments.length}'),
      empty: l.noPaymentsYet,
      children: [
        for (final p in sale.payments)
          DetailRow(
            leading: PaymentAvatar(paymentMethodIcon(p.method)),
            title:
                '${Fmt.date(p.paymentDate)} · ${l.paymentMethodText(p.method)}',
            subtitle: [
              if ((p.note ?? '').isNotEmpty) p.note!,
              if (p.createdBy != null) l.byUser(p.createdBy!),
            ].join(' · '),
            amount: Fmt.money(p.amount, decimals: true),
            amountColor: t.success,
            onLongPress: onDelete == null
                ? null
                : (row) => showActionMenu(
                    row,
                    groups: [
                      [
                        ActionMenuItem(
                          icon: Icons.delete_outline,
                          label: l.deletePayment,
                          destructive: true,
                          onSelected: () => onDelete!(p),
                        ),
                      ],
                    ],
                  ),
          ),
      ],
    );
  }
}

/// Sale detail while loading: header, customer, items, money and payments;
/// two columns on wide screens like the real page.
class SaleDetailSkeleton extends StatelessWidget {
  const SaleDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const header = SkeletonHeader(avatar: false);
    const customer = SkeletonHeader(buttons: 2);
    const items = SkeletonLines(count: 3, title: true);
    const money = SkeletonLines(count: 6, title: true);
    const payments = SkeletonLines(count: 2, title: true);
    const gap = SizedBox(height: Space.s3);
    if (MediaQuery.sizeOf(context).width >= Breakpoints.expanded) {
      return const DetailSkeleton(
        maxWidth: 1200,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(children: [header, gap, items, gap, payments]),
              ),
              SizedBox(width: Space.s5),
              Expanded(
                flex: 2,
                child: Column(children: [customer, gap, money]),
              ),
            ],
          ),
        ],
      );
    }
    return const DetailSkeleton(
      children: [header, gap, customer, gap, items, gap, money, gap, payments],
    );
  }
}
