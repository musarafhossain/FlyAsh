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
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../products/presentation/pages/products_list_page.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale.dart';
import '../sale_labels.dart';

/// Sale detail (04-UI-UX "Sale detail"): invoice no. and status pills →
/// customer card (Call / WhatsApp, opens the customer) → items → money
/// summary (subtotal, transport, discount, total, cost, profit, paid, due)
/// → payments. Actions (add payment, deliver, cancel, edit, share) come in
/// F11 and F17.
class SaleDetailPage extends ConsumerStatefulWidget {
  const SaleDetailPage({super.key, required this.saleId});

  final int saleId;

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

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final sale = await ref.read(salesRepositoryProvider).get(widget.saleId);
      if (mounted) setState(() => _sale = sale);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sale = _sale;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    return Scaffold(
      appBar: AppBar(title: Text(sale?.summary.invoiceNo ?? l.saleDetails)),
      body: sale == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const Center(child: CircularProgressIndicator()))
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
      _Payments(sale: sale),
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
                _Payments(sale: sale),
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
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.itemsCount('${sale.items.length}'),
            style: AppTypography.title.copyWith(color: t.textPrimary),
          ),
          for (final (i, item) in sale.items.indexed) ...[
            if (i > 0) Divider(height: Space.s5, color: t.border),
            if (i == 0) const SizedBox(height: Space.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProductIcon(size: 36),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: AppTypography.bodyStrong.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        '${Fmt.count(item.quantity)} × '
                        '${Fmt.money(item.unitPrice, decimals: true)} '
                        '${l.perUnit(unitText(l, item.unit))}',
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s2),
                Text(
                  Fmt.money(item.lineTotal),
                  style: AppTypography.bodyStrong.copyWith(
                    color: t.textPrimary,
                    fontFeatures: AppTypography.tabular,
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
  const _Payments({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.paymentsCount('${sale.payments.length}'),
            style: AppTypography.title.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: Space.s2),
          if (sale.payments.isEmpty)
            Text(
              l.noPaymentsYet,
              style: AppTypography.body.copyWith(color: t.textTertiary),
            ),
          for (final p in sale.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s2),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.successBg,
                      borderRadius: Radii.smAll,
                    ),
                    child: Icon(
                      _methodIcon(p.method),
                      size: 20,
                      color: t.success,
                    ),
                  ),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Fmt.date(p.paymentDate)} · '
                          '${l.paymentMethodText(p.method)}',
                          style: AppTypography.body.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                        if ((p.note ?? '').isNotEmpty || p.createdBy != null)
                          Text(
                            [
                              if ((p.note ?? '').isNotEmpty) p.note!,
                              if (p.createdBy != null) l.byUser(p.createdBy!),
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    Fmt.money(p.amount, decimals: true),
                    style: AppTypography.bodyStrong.copyWith(
                      color: t.success,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static IconData _methodIcon(String method) => switch (method) {
    'upi' => Icons.qr_code_2,
    'bank' => Icons.account_balance_outlined,
    'cheque' => Icons.receipt_outlined,
    'cash' => Icons.payments_outlined,
    _ => Icons.more_horiz,
  };
}
