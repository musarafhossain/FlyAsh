import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards.dart';
import '../domain/reports.dart';
import 'widgets/report_view.dart';

/// "01 Nov 2026 – 16 Nov 2026" (one date when from = to).
String periodText(String from, String to) =>
    from == to ? Fmt.date(from) : '${Fmt.date(from)} – ${Fmt.date(to)}';

/// "Nov" for a month "2026-11".
String monthShort(String ym) => Fmt.month(ym).split(' ').first;

/// The net profit report as a [ReportView], for the PDF / Excel export.
ReportView netProfitView(AppLocalizations l, NetProfitReport r) => ReportView(
  title: l.reportNetProfit,
  period: periodText(r.from, r.to),
  summary: [
    ReportFigure(
      l.salesWithTax,
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
      l.wagesPaid,
      Fmt.money(r.wagesPaid),
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
  tables: [
    ReportTable(
      title: l.byMonth,
      columns: [
        ReportColumn(l.monthColumn, flex: 3),
        ReportColumn(l.salesWithTax, numeric: true, flex: 3),
        ReportColumn(l.reportExpenses, numeric: true, flex: 3),
        ReportColumn(l.wagesPaid, numeric: true, flex: 3),
        ReportColumn(l.netProfit, numeric: true, flex: 3),
      ],
      rows: [
        for (final m in r.monthly)
          [
            Fmt.month(m.month),
            Fmt.money(m.sales),
            Fmt.money(m.expenses),
            Fmt.money(m.wagesPaid),
            Fmt.money(m.netProfit),
          ],
      ],
    ),
  ],
);
