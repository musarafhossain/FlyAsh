import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/motion.dart';

/// One report, described once: the screen draws it and the export turns the
/// same description into PDF and Excel (so they always match).
@immutable
class ReportView {
  const ReportView({
    required this.title,
    required this.period,
    required this.summary,
    this.chart,
    this.tables = const [],
  });

  final String title;

  /// "01 Nov 2026 – 16 Nov 2026", "Nov 2026" or "" (dues).
  final String period;
  final List<ReportFigure> summary;
  final ReportChart? chart;
  final List<ReportTable> tables;
}

/// A summary number (shown as a stat card).
@immutable
class ReportFigure {
  const ReportFigure(this.label, this.value, this.icon, this.tint);
  final String label;
  final String value;
  final IconData icon;
  final KpiTint tint;
}

enum ReportChartKind {
  /// Upright bars over time (days, months).
  bars,

  /// Labelled horizontal bars (categories, labours) — easier to read than a
  /// pie for a few named parts.
  horizontalBars,
}

/// One series (one colour, no legend: the title names it).
@immutable
class ReportChart {
  const ReportChart({
    required this.title,
    required this.kind,
    required this.points,
    required this.valueText,
    this.shortLabel,
  });

  final String title;
  final ReportChartKind kind;

  /// (label, value), in the order to draw.
  final List<(String, double)> points;

  /// How a value reads in tooltips and bar labels ("₹4,050").
  final String Function(double value) valueText;

  /// Axis label for a point (e.g. "05" for a date); defaults to the label.
  final String Function(String label)? shortLabel;
}

@immutable
class ReportColumn {
  const ReportColumn(this.label, {this.numeric = false, this.flex = 2});
  final String label;
  final bool numeric;
  final int flex;
}

@immutable
class ReportTable {
  const ReportTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.onTapRow,
  });

  final String title;
  final List<ReportColumn> columns;
  final List<List<String>> rows;
  final void Function(int row)? onTapRow;
}

/// The report body: stat cards, chart, tables.
class ReportBody extends StatelessWidget {
  const ReportBody({super.key, required this.view, required this.emptyText});

  final ReportView view;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final c = view.chart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiRow(
          children: [
            for (final f in view.summary)
              KpiChip(
                icon: f.icon,
                label: f.label,
                value: f.value,
                tint: f.tint,
              ),
          ],
        ),
        if (c != null) ...[
          SectionHeader(c.title),
          AppCard(
            key: const Key('reportChart'),
            child: c.points.isEmpty
                ? _Empty(emptyText)
                : c.kind == ReportChartKind.bars
                ? ReportBarChart(chart: c)
                : ReportHorizontalBars(chart: c),
          ),
        ],
        for (final table in view.tables) ...[
          // No title when the chart above already names it.
          if (table.title.isEmpty)
            const SizedBox(height: Space.s3)
          else
            SectionHeader(table.title),
          ReportTableCard(table: table, emptyText: emptyText),
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.s4),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.body.copyWith(color: context.tokens.textTertiary),
    ),
  );
}

/// Upright bars (one series in the accent colour; losses in the error
/// colour). Tap a bar for its date and amount. Thin bars with rounded tops,
/// a recessive grid, labels thinned out when there are many days.
class ReportBarChart extends StatelessWidget {
  const ReportBarChart({super.key, required this.chart});

  final ReportChart chart;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final points = chart.points;
    final values = points.map((p) => p.$2);
    final maxY = values.fold<double>(0, (a, b) => b > a ? b : a);
    final minY = values.fold<double>(0, (a, b) => b < a ? b : a);
    final span = (maxY - minY) == 0 ? 1.0 : maxY - minY;
    // At most ~7 axis labels, whatever the number of bars.
    final every = (points.length / 7).ceil().clamp(1, 1000);
    final barWidth = (220 / points.length).clamp(4.0, 18.0);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY + span * 0.12,
          minY: minY < 0 ? minY - span * 0.12 : 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          // A zero line when there are losses.
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (minY < 0)
                HorizontalLine(y: 0, color: t.textTertiary, strokeWidth: 1),
            ],
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: t.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length || i % every != 0) {
                    return const SizedBox.shrink();
                  }
                  final label = points[i].$1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      chart.shortLabel?.call(label) ?? label,
                      style: AppTypography.micro.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => t.textPrimary,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${points[group.x].$1}\n${chart.valueText(rod.toY)}',
                AppTypography.caption.copyWith(color: t.surface),
              ),
            ),
          ),
          barGroups: [
            for (final (i, p) in points.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: p.$2,
                    width: barWidth,
                    color: p.$2 < 0 ? t.error : t.primary,
                    borderRadius: p.$2 < 0
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          )
                        : const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
        duration: Motion.reduced(context) ? Duration.zero : Motion.base,
      ),
    );
  }
}

/// Named horizontal bars: label and amount on one line, the bar below (the
/// value is always written, so no tooltip is needed).
class ReportHorizontalBars extends StatelessWidget {
  const ReportHorizontalBars({super.key, required this.chart});

  final ReportChart chart;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final max = chart.points.fold<double>(0, (a, p) => p.$2 > a ? p.$2 : a);
    return Column(
      children: [
        for (final (label, value) in chart.points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      chart.valueText(value),
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.textPrimary,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, box) => Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: Motion.reduced(context)
                          ? Duration.zero
                          : Motion.base,
                      height: 8,
                      width: max <= 0
                          ? 0
                          : (box.maxWidth * value / max).clamp(2, box.maxWidth),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A plain table in a card: a header row and rows split by lines; numbers
/// on the right in tabular figures. Tappable rows when [ReportTable.onTapRow].
class ReportTableCard extends StatelessWidget {
  const ReportTableCard({
    super.key,
    required this.table,
    required this.emptyText,
  });

  final ReportTable table;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget cells(List<String> values, {required bool header}) => Row(
      children: [
        for (final (i, col) in table.columns.indexed)
          Expanded(
            flex: col.flex,
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : Space.s2),
              child: Text(
                values[i],
                maxLines: header ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: col.numeric ? TextAlign.right : TextAlign.left,
                style: header
                    ? AppTypography.caption.copyWith(
                        color: t.textSecondary,
                        fontWeight: FontWeight.w600,
                      )
                    : AppTypography.body.copyWith(
                        color: t.textPrimary,
                        fontFeatures: col.numeric
                            ? AppTypography.tabular
                            : null,
                      ),
              ),
            ),
          ),
      ],
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.s4,
              Space.s3,
              Space.s4,
              Space.s2,
            ),
            child: cells([
              for (final c in table.columns) c.label,
            ], header: true),
          ),
          const Divider(height: 1),
          if (table.rows.isEmpty) _Empty(emptyText),
          for (final (i, row) in table.rows.indexed) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: table.onTapRow == null ? null : () => table.onTapRow!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s4,
                  vertical: Space.s3,
                ),
                child: cells(row, header: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
