import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/data_changed.dart';
import '../../../../core/network/session.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/reports_repository_impl.dart';
import '../../domain/reports.dart';
import '../report_export.dart';
import '../report_views.dart';
import '../widgets/report_view.dart';

/// Reports = net profit (03-AppFlow §9): period chips → Sales (with tax) ·
/// Expenses · Wages paid · Net profit → net profit by month (chart and a
/// card per month). Export (next to the dates) → PDF / Excel.
///
/// While loading, the same cards show with pulsing placeholders instead of
/// the numbers, so nothing moves when the data arrives.
class NetProfitPage extends ConsumerStatefulWidget {
  const NetProfitPage({super.key});

  @override
  ConsumerState<NetProfitPage> createState() => _NetProfitPageState();
}

class _NetProfitPageState extends ConsumerState<NetProfitPage> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateRange _custom = const DateRange();

  NetProfitReport? _data;
  Object? _error;
  bool _exporting = false;

  /// Ignores answers to an older request.
  int _request = 0;

  String get _today => ref.read(businessDateProvider);

  DateRange get _range =>
      _period == ReportPeriod.custom ? _custom : reportRange(_period, _today);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _error = null);
    try {
      final data = await ref.read(reportsRepositoryProvider).netProfit(_range);
      if (mounted && request == _request) setState(() => _data = data);
    } on Failure catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    }
  }

  Future<void> _choose(ReportPeriod p) async {
    if (p == ReportPeriod.custom) {
      final today = Ymd.parse(_today);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(today.year, today.month, today.day),
      );
      if (picked == null || !mounted) return;
      String ymd(DateTime d) =>
          Ymd.format(DateTime.utc(d.year, d.month, d.day));
      _custom = DateRange(from: ymd(picked.start), to: ymd(picked.end));
    }
    setState(() {
      _period = p;
      _data = null;
    });
    unawaited(_load());
  }

  Future<void> _export({required bool pdf}) async {
    final data = _data;
    if (data == null) return;
    final l = context.l10n;
    final view = netProfitView(l, data);
    setState(() => _exporting = true);
    try {
      final name = reportFileName('net-profit', '${_range.from}_${_range.to}');
      final generated = l.generatedOn(
        Fmt.dateTime(DateTime.now().toUtc().toIso8601String()),
      );
      if (pdf) {
        await sharePdf(
          await buildReportPdf(
            view,
            generatedOn: generated,
            accent: AppColors.accent(
              ref.read(themeControllerProvider).accent,
              Brightness.light,
            ).primary.toARGB32(),
          ),
          name,
        );
      } else {
        await shareExcel(buildReportExcel(view, generatedOn: generated), name);
      }
    } catch (_) {
      if (mounted) showMessage(context, l.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A new sale, expense or wage payment anywhere reloads the report.
    ref.onDataChanged({DataTag.reports}, () => unawaited(_load()));
    final l = context.l10n;
    final t = context.tokens;
    final data = _data;
    final range = _range;
    final loading = data == null;
    final net = Decimal.tryParse(data?.netProfit ?? '0') ?? Decimal.zero;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        // The section's name (the sidebar says Reports too).
        title: Text(l.navReports),
        actions: const [AppBarActions()],
      ),
      body: PageBody(
        maxWidth: 960,
        onRefresh: _load,
        children: [
          Wrap(
            key: const Key('reportPeriods'),
            spacing: Space.s2,
            children: [
              for (final (p, label) in [
                (ReportPeriod.today, l.presetToday),
                (ReportPeriod.last7Days, l.presetLast7Days),
                (ReportPeriod.thisMonth, l.presetThisMonth),
                (ReportPeriod.lastMonth, l.presetLastMonth),
                (ReportPeriod.thisYear, l.presetThisYear),
                (ReportPeriod.custom, l.presetCustom),
              ])
                CompactChoiceChip(
                  key: Key('period-${p.name}'),
                  label: label,
                  selected: _period == p,
                  onSelected: (_) => _choose(p),
                ),
            ],
          ),
          // The dates · Export (PDF / Excel). Export sits here, not in the
          // app bar, so the title has room on a phone.
          Row(
            children: [
              Expanded(
                child: Text(
                  range.from == null
                      ? ''
                      : periodText(range.from!, range.to ?? range.from!),
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ),
              Builder(
                builder: (anchor) => TextButton.icon(
                  key: const Key('reportExport'),
                  onPressed: data == null || _exporting
                      ? null
                      : () => showActionMenu(
                          anchor,
                          groups: [
                            [
                              ActionMenuItem(
                                icon: Icons.picture_as_pdf_outlined,
                                label: l.exportPdf,
                                onSelected: () => _export(pdf: true),
                              ),
                              ActionMenuItem(
                                icon: Icons.table_view_outlined,
                                label: l.exportExcel,
                                onSelected: () => _export(pdf: false),
                              ),
                            ],
                          ],
                        ),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(l.export),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s2),
          if (_error != null)
            ErrorState(message: failureText(context, _error!), onRetry: _load)
          else ...[
            KpiRow(
              children: [
                KpiChip(
                  icon: Icons.trending_up,
                  label: l.salesWithTax,
                  value: Fmt.money(data?.sales),
                  tint: KpiTint.sky,
                  loading: loading,
                ),
                KpiChip(
                  icon: Icons.receipt_long_outlined,
                  label: l.reportExpenses,
                  value: Fmt.money(data?.expenses),
                  tint: KpiTint.amber,
                  loading: loading,
                ),
                KpiChip(
                  icon: Icons.engineering_outlined,
                  label: l.wagesPaid,
                  value: Fmt.money(data?.wagesPaid),
                  tint: KpiTint.rose,
                  loading: loading,
                ),
                KpiChip(
                  key: const Key('netProfitChip'),
                  icon: Icons.savings_outlined,
                  label: l.netProfit,
                  value: Fmt.money(data?.netProfit),
                  tint: net < Decimal.zero ? KpiTint.rose : KpiTint.green,
                  loading: loading,
                ),
              ],
            ),
            SectionHeader(l.byMonth),
            AppCard(
              key: const Key('reportChart'),
              child: loading
                  ? const _ChartPlaceholder()
                  : data.monthly.isEmpty
                  ? _Empty(l.noReportData)
                  : ReportBarChart(
                      chart: ReportChart(
                        title: l.byMonth,
                        kind: ReportChartKind.bars,
                        points: [
                          for (final m in data.monthly)
                            (
                              Fmt.month(m.month),
                              double.tryParse(m.netProfit) ?? 0,
                            ),
                        ],
                        valueText: (v) => Fmt.money(v.toStringAsFixed(2)),
                        shortLabel: (label) => label.split(' ').first,
                      ),
                    ),
            ),
            const SizedBox(height: Space.s3),
            // Newest month first; a card per month (no wide table).
            if (loading)
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(height: Space.s2),
                const _MonthCard(month: null),
              ]
            else
              for (final (i, m) in data.monthly.reversed.indexed) ...[
                if (i > 0) const SizedBox(height: Space.s2),
                _MonthCard(month: m),
              ],
          ],
          const SizedBox(height: Space.s6),
        ],
      ),
    );
  }
}

/// One month: name and net profit, then Sales · Expenses · Wages paid.
/// [month] null = loading (same card, placeholders for the text).
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month});

  final MonthProfit? month;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final m = month;
    final net = Decimal.tryParse(m?.netProfit ?? '0') ?? Decimal.zero;

    Widget figure(String label, String? value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 2),
          if (value == null)
            SkeletonLine(style: AppTypography.bodyStrong, widthFactor: 0.7)
          else
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Full line height even when the amount shrinks to fit.
                Text(
                  '0',
                  style: AppTypography.bodyStrong.copyWith(
                    color: Colors.transparent,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.money(value),
                    style: AppTypography.bodyStrong.copyWith(
                      color: t.textPrimary,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return AppCard(
      key: m == null ? null : Key('month-${m.month}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (m == null)
                SkeletonLine(style: AppTypography.title, width: 90)
              else
                Text(
                  Fmt.month(m.month),
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
              const Spacer(),
              if (m == null)
                SkeletonLine(style: AppTypography.title, width: 80)
              else
                Text(
                  Fmt.money(m.netProfit),
                  style: AppTypography.title.copyWith(
                    color: net < Decimal.zero ? t.error : t.success,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Row(
            children: [
              figure(l.salesWithTax, m?.sales),
              const SizedBox(width: Space.s3),
              figure(l.reportExpenses, m?.expenses),
              const SizedBox(width: Space.s3),
              figure(l.wagesPaid, m?.wagesPaid),
            ],
          ),
        ],
      ),
    );
  }
}

/// The chart card while loading: a few pulsing bars of the chart's height.
class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final h in const [90.0, 140.0, 110.0, 160.0, 70.0])
          SkeletonBox(width: 18, height: h, radius: 4),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.s6),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.body.copyWith(color: context.tokens.textTertiary),
    ),
  );
}
