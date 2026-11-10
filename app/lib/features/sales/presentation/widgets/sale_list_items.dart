import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/sale.dart';
import '../../domain/sale_summary.dart';
import '../sale_labels.dart';

/// One sale in a list (04-UI-UX Sales list row):
///   [avatar] Customer name                ₹ total
///            INV-000104 · 08 Nov 2026     (pill)
/// Without [showCustomer] (customer page) the invoice no. is the title.
class SaleTile extends StatelessWidget {
  const SaleTile({
    super.key,
    required this.sale,
    this.onTap,
    this.showCustomer = false,
    this.showDelivery = false,
    this.action,
  });

  final SaleSummary sale;
  final VoidCallback? onTap;
  final bool showCustomer;

  /// A button shown under the row (e.g. "Mark delivered").
  final Widget? action;

  /// Upcoming deliveries: the delivery date instead of the sale date, and
  /// an "Overdue" pill when it has passed.
  final bool showDelivery;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final s = sale;
    final date = showDelivery && s.deliveryDate != null
        ? l.deliverOn(Fmt.date(s.deliveryDate))
        : Fmt.date(s.saleDate);
    final title = showCustomer ? (s.customerName ?? s.invoiceNo) : s.invoiceNo;
    final subtitle = showCustomer
        ? '${s.invoiceNo} · $date'
        : '$date · ${l.saleTypeText(s.type)}';

    return Opacity(
      opacity: s.isCancelled ? 0.6 : 1,
      child: ListRowSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (showCustomer) ...[
                  InitialsAvatar(s.customerName ?? '?'),
                  const SizedBox(width: Space.s3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: s.isOverdue ? t.error : t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.money(s.total),
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.textPrimary,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    const SizedBox(height: Space.s1),
                    if (showDelivery && s.isOverdue)
                      StatusPill(l.overdue, tone: StatusTone.error)
                    else
                      SaleStatusPill(s),
                  ],
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: Space.s2),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desktop table of sales. [showCustomer] adds the customer column.
class SalesTable extends StatelessWidget {
  const SalesTable({
    super.key,
    required this.sales,
    this.onOpen,
    this.showCustomer = false,
    this.showDelivery = false,
    this.actionBuilder,
  });

  final List<SaleSummary> sales;
  final ValueChanged<SaleSummary>? onOpen;
  final bool showCustomer;
  final bool showDelivery;

  /// Last column with a button per row (e.g. "Mark delivered").
  final Widget Function(SaleSummary sale)? actionBuilder;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return DataTableCard(
      columns: [
        TableColumnDef(l.invoiceNo, flex: 2),
        if (showCustomer) TableColumnDef(l.customerDetails, flex: 3),
        TableColumnDef(showDelivery ? l.deliveryDate : l.date, flex: 2),
        TableColumnDef(l.type, flex: 2),
        TableColumnDef(l.total, flex: 2, alignEnd: true),
        TableColumnDef(l.due, flex: 2, alignEnd: true),
        TableColumnDef(l.status, flex: 2, alignEnd: true),
        if (actionBuilder != null)
          const TableColumnDef('', flex: 3, alignEnd: true),
      ],
      rows: [
        for (final s in sales)
          [
            CellText(s.invoiceNo, strong: true),
            if (showCustomer)
              Row(
                children: [
                  InitialsAvatar(s.customerName ?? '?', size: 32),
                  const SizedBox(width: Space.s3),
                  Expanded(child: CellText(s.customerName ?? '—')),
                ],
              ),
            Text(
              Fmt.date(showDelivery ? s.deliveryDate : s.saleDate),
              maxLines: 1,
              style: AppTypography.body.copyWith(
                color: s.isOverdue ? t.error : t.textSecondary,
              ),
            ),
            CellText(l.saleTypeText(s.type)),
            CellText(Fmt.money(s.total)),
            _DueCell(sale: s),
            if (showDelivery && s.isOverdue)
              StatusPill(l.overdue, tone: StatusTone.error)
            else
              SaleStatusPill(s),
            if (actionBuilder != null) actionBuilder!(s),
          ],
      ],
      onTapRow: onOpen == null ? null : (i) => onOpen!(sales[i]),
    );
  }
}

class _DueCell extends StatelessWidget {
  const _DueCell({required this.sale});

  final SaleSummary sale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final none = sale.isCancelled || Sale.isZeroAmount(sale.dueAmount);
    return Text(
      none ? '—' : Fmt.money(sale.dueAmount),
      style: AppTypography.body.copyWith(
        color: none ? t.textTertiary : t.error,
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}
