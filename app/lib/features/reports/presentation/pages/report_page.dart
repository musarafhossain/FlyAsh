import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/data_changed.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/action_menu.dart';
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

/// One report (03-AppFlow §9): period (presets + custom, or a month for
/// wages, none for dues) → stat cards → chart → tables. ⋮ → Export PDF /
/// Excel, made on the device from what is shown.
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key, required this.type});

  final ReportType type;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateRange _custom = const DateRange();
  late String _month = _today.substring(0, 7);

  Object? _data;
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
    final repo = ref.read(reportsRepositoryProvider);
    try {
      final Object data = switch (widget.type) {
        ReportType.sales => await repo.sales(_range),
        ReportType.expenses => await repo.expenses(_range),
        ReportType.netProfit => await repo.netProfit(_range),
        ReportType.collections => await repo.collections(_range),
        ReportType.wages => await repo.wages(_month),
        ReportType.dues => await repo.dues(),
      };
      if (mounted && request == _request) setState(() => _data = data);
    } on Failure catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    }
  }

  /// Built on every build, so a language change shows at once.
  ReportView _viewOf(AppLocalizations l, Object data) => switch (data) {
    final SalesReport r => salesView(l, r),
    final ExpenseReport r => expensesView(l, r),
    final NetProfitReport r => netProfitView(l, r),
    final CollectionsReport r => collectionsView(l, r),
    final WageReport r => wagesView(l, r),
    final DuesReport r => duesView(
      l,
      r,
      onOpen: (row) => context.push('/customers/${row.customerId}'),
    ),
    _ => throw ArgumentError(data),
  };

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

  void _moveMonth(int by) {
    setState(() {
      _month = Ymd.addMonths('$_month-01', by).substring(0, 7);
      _data = null;
    });
    unawaited(_load());
  }

  Future<void> _export({required bool pdf}) async {
    final data = _data;
    if (data == null) return;
    final l = context.l10n;
    final view = _viewOf(l, data);
    setState(() => _exporting = true);
    try {
      final key = widget.type == ReportType.wages
          ? _month
          : widget.type == ReportType.dues
          ? _today
          : '${_range.from}_${_range.to}';
      final name = reportFileName(widget.type.path, key);
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

  String _title(AppLocalizations l) => switch (widget.type) {
    ReportType.sales => l.reportSales,
    ReportType.dues => l.reportDues,
    ReportType.expenses => l.reportExpenses,
    ReportType.wages => l.reportWages,
    ReportType.netProfit => l.reportNetProfit,
    ReportType.collections => l.reportCollections,
  };

  @override
  Widget build(BuildContext context) {
    // A change anywhere (a new sale, expense …) reloads the report.
    ref.onDataChanged({DataTag.reports}, () => unawaited(_load()));
    final l = context.l10n;
    final t = context.tokens;
    final data = _data;
    final view = data == null ? null : _viewOf(l, data);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l)),
        actions: [
          ActionMenuButton(
            tooltip: l.moreActions,
            enabled: view != null && !_exporting,
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
        ],
      ),
      body: PageBody(
        maxWidth: 960,
        onRefresh: _load,
        children: [
          if (widget.type.usesRange) ...[
            Wrap(
              key: const Key('reportPeriods'),
              spacing: Space.s2,
              children: [
                for (final (p, label) in [
                  (ReportPeriod.today, l.presetToday),
                  (ReportPeriod.thisWeek, l.presetThisWeek),
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
            if (_range.from != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.s1),
                child: Text(
                  periodText(_range.from!, _range.to ?? _range.from!),
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ),
            const SizedBox(height: Space.s3),
          ],
          if (widget.type == ReportType.wages) ...[
            PeriodSelector(
              label: Fmt.month(_month),
              onPrevious: () => _moveMonth(-1),
              onNext: _month.compareTo(_today.substring(0, 7)) < 0
                  ? () => _moveMonth(1)
                  : null,
            ),
            const SizedBox(height: Space.s3),
          ],
          if (_error != null)
            ErrorState(message: failureText(context, _error!), onRetry: _load)
          else if (view == null)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonKpis(count: 2),
                SkeletonSectionTitle(),
                SkeletonCard(child: SizedBox(height: 168)),
                SkeletonSectionTitle(),
                SkeletonRows(
                  count: 4,
                  avatar: false,
                  subtitle: false,
                  trailing: SkeletonTrailing.amount,
                ),
              ],
            )
          else
            ReportBody(view: view, emptyText: l.noReportData),
          const SizedBox(height: Space.s6),
        ],
      ),
    );
  }
}
