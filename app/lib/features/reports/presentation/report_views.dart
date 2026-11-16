import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
import '../../sales/presentation/sale_labels.dart';
import '../domain/reports.dart';
import 'widgets/report_view.dart';

/// Builds each report's [ReportView] from its data (01-PRD §5.10).

double _num(String v) => double.tryParse(v) ?? 0;
String _moneyOf(double v) => Fmt.money(v.toStringAsFixed(2));

/// "01 Nov 2026 – 16 Nov 2026" (one date when from = to).
String periodText(String from, String to) =>
    from == to ? Fmt.date(from) : '${Fmt.date(from)} – ${Fmt.date(to)}';

/// "Nov" for a month "2026-11".
String _monthShort(String ym) => Fmt.month(ym).split(' ').first;

ReportView salesView(AppLocalizations l, SalesReport r) => ReportView(
  title: l.reportSales,
  period: periodText(r.from, r.to),
  summary: [
    ReportFigure(
      l.salesAmount,
      Fmt.money(r.amount),
      Icons.trending_up,
      KpiTint.sky,
    ),
    ReportFigure(
      l.salesCountLabelShort,
      '${r.count}',
      Icons.receipt_long_outlined,
      KpiTint.green,
    ),
  ],
  chart: ReportChart(
    title: l.byDay,
    kind: ReportChartKind.bars,
    points: [for (final d in r.daily) (Fmt.date(d.date), _num(d.amount))],
    valueText: _moneyOf,
    shortLabel: (label) => label.split(' ').first,
  ),
  tables: [
    ReportTable(
      title: l.byProduct,
      columns: [
        ReportColumn(l.productColumn, flex: 4),
        ReportColumn(l.quantityColumn, numeric: true),
        ReportColumn(l.amountColumn, numeric: true, flex: 3),
      ],
      rows: [
        for (final p in r.byProduct)
          [p.name, Fmt.count(p.quantity), Fmt.money(p.amount)],
      ],
    ),
    ReportTable(
      title: l.byDay,
      columns: [
        ReportColumn(l.dateColumn, flex: 3),
        ReportColumn(l.amountColumn, numeric: true, flex: 3),
      ],
      rows: [
        for (final d in r.daily) [Fmt.date(d.date), Fmt.money(d.amount)],
      ],
    ),
  ],
);

ReportView duesView(
  AppLocalizations l,
  DuesReport r, {
  void Function(DueRow row)? onOpen,
}) => ReportView(
  title: l.reportDues,
  period: '',
  summary: [
    ReportFigure(
      l.totalDueLabel,
      Fmt.money(r.grandTotal),
      Icons.account_balance_wallet_outlined,
      KpiTint.rose,
    ),
    ReportFigure(
      l.navCustomers,
      '${r.rows.length}',
      Icons.people_outline,
      KpiTint.sky,
    ),
  ],
  tables: [
    ReportTable(
      title: l.customersWithDue,
      columns: [
        ReportColumn(l.customerColumn, flex: 4),
        ReportColumn(l.oldestDueColumn, flex: 3),
        ReportColumn(l.totalDueLabel, numeric: true, flex: 3),
      ],
      rows: [
        for (final d in r.rows)
          [
            d.phone.isEmpty ? d.name : '${d.name}\n${d.phone}',
            Fmt.date(d.oldestDueDate),
            Fmt.money(d.totalDue),
          ],
      ],
      onTapRow: onOpen == null ? null : (i) => onOpen(r.rows[i]),
    ),
  ],
);

ReportView expensesView(AppLocalizations l, ExpenseReport r) => ReportView(
  title: l.reportExpenses,
  period: periodText(r.from, r.to),
  summary: [
    ReportFigure(
      l.total,
      Fmt.money(r.total),
      Icons.receipt_long_outlined,
      KpiTint.amber,
    ),
    ReportFigure(
      l.topCategory,
      r.byCategory.isEmpty ? '–' : r.byCategory.first.name,
      Icons.category_outlined,
      KpiTint.sky,
    ),
  ],
  chart: ReportChart(
    title: l.byCategory,
    kind: ReportChartKind.horizontalBars,
    points: [for (final c in r.byCategory) (c.name, _num(c.amount))],
    valueText: _moneyOf,
  ),
  tables: [
    ReportTable(
      title: '',
      columns: [
        ReportColumn(l.categoryColumn, flex: 4),
        ReportColumn(l.shareColumn, numeric: true),
        ReportColumn(l.amountColumn, numeric: true, flex: 3),
      ],
      rows: [
        for (final c in r.byCategory)
          [c.name, '${c.percent.toStringAsFixed(1)}%', Fmt.money(c.amount)],
      ],
    ),
  ],
);

ReportView wagesView(AppLocalizations l, WageReport r) => ReportView(
  title: l.reportWages,
  period: Fmt.month(r.month),
  summary: [
    ReportFigure(
      l.earned,
      Fmt.money(r.earned),
      Icons.payments_outlined,
      KpiTint.sky,
    ),
    ReportFigure(
      l.paid,
      Fmt.money(r.paid),
      Icons.check_circle_outline,
      KpiTint.green,
    ),
    ReportFigure(
      l.balance,
      Fmt.money(r.balance),
      Icons.account_balance_wallet_outlined,
      KpiTint.rose,
    ),
  ],
  chart: ReportChart(
    title: l.earned,
    kind: ReportChartKind.horizontalBars,
    points: [
      for (final w in [
        ...r.rows,
      ]..sort((a, b) => _num(b.earned).compareTo(_num(a.earned))))
        (w.name, _num(w.earned)),
    ],
    valueText: _moneyOf,
  ),
  tables: [
    ReportTable(
      title: l.labourColumn,
      columns: [
        ReportColumn(l.labourColumn, flex: 4),
        ReportColumn(l.daysColumn, numeric: true),
        ReportColumn(l.earned, numeric: true, flex: 3),
        ReportColumn(l.paid, numeric: true, flex: 3),
        ReportColumn(l.balance, numeric: true, flex: 3),
      ],
      rows: [
        for (final w in r.rows)
          [
            w.name,
            '${w.presentDays}',
            Fmt.money(w.earned),
            Fmt.money(w.paid),
            Fmt.money(w.balance),
          ],
      ],
    ),
  ],
);

ReportView netProfitView(AppLocalizations l, NetProfitReport r) => ReportView(
  title: l.reportNetProfit,
  period: periodText(r.from, r.to),
  summary: [
    ReportFigure(
      l.salesNoTax,
      Fmt.money(r.sales),
      Icons.trending_up,
      KpiTint.sky,
    ),
    ReportFigure(
      l.reportExpenses,
      Fmt.money(r.expenses),
      Icons.receipt_long_outlined,
      KpiTint.amber,
    ),
    ReportFigure(
      l.reportWages,
      Fmt.money(r.wages),
      Icons.engineering_outlined,
      KpiTint.rose,
    ),
    ReportFigure(
      l.netProfit,
      Fmt.money(r.netProfit),
      Icons.savings_outlined,
      KpiTint.green,
    ),
  ],
  chart: ReportChart(
    title: '${l.netProfit} · ${l.byMonth}',
    kind: ReportChartKind.bars,
    points: [
      for (final m in r.monthly) (Fmt.month(m.month), _num(m.netProfit)),
    ],
    valueText: _moneyOf,
    shortLabel: (label) => label.split(' ').first,
  ),
  tables: [
    ReportTable(
      title: l.byMonth,
      columns: [
        ReportColumn(l.monthColumn, flex: 3),
        ReportColumn(l.salesColumn, numeric: true, flex: 3),
        ReportColumn(l.reportExpenses, numeric: true, flex: 3),
        ReportColumn(l.reportWages, numeric: true, flex: 3),
        ReportColumn(l.netProfit, numeric: true, flex: 3),
      ],
      rows: [
        for (final m in r.monthly)
          [
            _monthShort(m.month),
            Fmt.money(m.sales),
            Fmt.money(m.expenses),
            Fmt.money(m.wages),
            Fmt.money(m.netProfit),
          ],
      ],
    ),
  ],
);

ReportView collectionsView(AppLocalizations l, CollectionsReport r) =>
    ReportView(
      title: l.reportCollections,
      period: periodText(r.from, r.to),
      summary: [
        ReportFigure(
          l.received,
          Fmt.money(r.total),
          Icons.payments_outlined,
          KpiTint.green,
        ),
      ],
      chart: ReportChart(
        title: l.byDay,
        kind: ReportChartKind.bars,
        points: [for (final d in r.daily) (Fmt.date(d.date), _num(d.amount))],
        valueText: _moneyOf,
        shortLabel: (label) => label.split(' ').first,
      ),
      tables: [
        ReportTable(
          title: l.byMethod,
          columns: [
            ReportColumn(l.methodColumn, flex: 3),
            ReportColumn(l.amountColumn, numeric: true, flex: 3),
          ],
          rows: [
            for (final m in r.byMethod)
              [l.paymentMethodText(m.method), Fmt.money(m.amount)],
          ],
        ),
        ReportTable(
          title: l.byDay,
          columns: [
            ReportColumn(l.dateColumn, flex: 3),
            ReportColumn(l.amountColumn, numeric: true, flex: 3),
          ],
          rows: [
            for (final d in r.daily) [Fmt.date(d.date), Fmt.money(d.amount)],
          ],
        ),
      ],
    );
