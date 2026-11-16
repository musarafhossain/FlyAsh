import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
