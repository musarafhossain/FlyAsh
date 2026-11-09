import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../labours/presentation/labour_labels.dart';
import '../../../sales/presentation/sale_labels.dart';
import '../../data/wages_repository_impl.dart';
import '../../domain/wages.dart';
import '../widgets/wage_sheets.dart';
import '../widgets/wages_tab.dart';

/// A labour's wage for a month (03-AppFlow §7.3): breakdown
/// worked days × rate − advances − paid = balance, Give advance / Pay
/// wage, advances and payments (⋮ → Delete), and the day-by-day list.
class WageDetailPage extends ConsumerStatefulWidget {
  const WageDetailPage({super.key, required this.labourId, this.month});

  final String labourId;

  /// `?month=YYYY-MM`; default this month.
  final String? month;

  @override
  ConsumerState<WageDetailPage> createState() => _WageDetailPageState();
}

class _WageDetailPageState extends ConsumerState<WageDetailPage> {
  late String _month = _validMonth(widget.month);
  WageDetail? _detail;
  Object? _error;
  bool _busy = false;
  bool _showDays = false;

  String get _today => ref.read(businessDateProvider);
  String get _thisMonth => _today.substring(0, 7);

  String _validMonth(String? ym) {
    final now = ref.read(businessDateProvider).substring(0, 7);
    final ok = ym != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(ym);
    return ok && ym.compareTo(now) <= 0 ? ym : now;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final month = _month;
    setState(() => _error = null);
    try {
      final d = await ref
          .read(wagesRepositoryProvider)
          .detail(widget.labourId, month);
      if (mounted && month == _month) setState(() => _detail = d);
    } on Failure catch (e) {
      if (mounted && month == _month) setState(() => _error = e);
    }
  }

  void _moveMonth(int by) {
    setState(() {
      _month = Ymd.addMonths('$_month-01', by).substring(0, 7);
      _detail = null;
    });
    _load();
  }

  /// Runs an action, shows its message and reloads the month.
  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final message = await action();
      if (!mounted) return;
      showMessage(context, message);
      await _load();
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _giveAdvance() async {
    final row = _detail!.row;
    // A past month's advance is dated in that month (deducted there).
    final defaultDate = _month == _thisMonth
        ? _today
        : Ymd.monthEnd('$_month-01');
    final entry = await showAdvanceSheet(
      context,
      labourName: row.name,
      defaultDate: defaultDate,
      today: _today,
    );
    if (entry == null) return;
    await _run(
      () => ref
          .read(wagesRepositoryProvider)
          .giveAdvance(
            widget.labourId,
            amount: entry.amount,
            date: entry.date,
            note: entry.note,
          ),
    );
  }

  Future<void> _payWage() async {
    final row = _detail!.row;
    final entry = await showPayWageSheet(
      context,
      labourName: row.name,
      month: _month,
      balance: row.balance,
      today: _today,
    );
    if (entry == null) return;
    await _run(
      () => ref
          .read(wagesRepositoryProvider)
          .pay(
            widget.labourId,
            month: _month,
            amount: entry.amount,
            date: entry.date,
            method: entry.method,
            note: entry.note,
          ),
    );
  }

  Future<void> _delete({
    required String title,
    required Future<String> Function() action,
  }) async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: title,
      message: l.balanceRecalculated,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (ok) await _run(action);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.row.name ?? l.wageDetails),
        actions: [
          if (d != null)
            IconButton(
              tooltip: l.labourDetails,
              onPressed: () => context.push('/labours/${widget.labourId}'),
              icon: const Icon(Icons.person_outline),
            ),
        ],
      ),
      body: PageBody(
        maxWidth: 760,
        children: [
          PeriodSelector(
            label: Fmt.month(_month),
            onPrevious: () => _moveMonth(-1),
            onNext: _month.compareTo(_thisMonth) < 0
                ? () => _moveMonth(1)
                : null,
          ),
          const SizedBox(height: Space.s3),
          if (_error != null)
            ErrorState(message: failureText(context, _error!), onRetry: _load)
          else if (d == null)
            const Padding(
              padding: EdgeInsets.all(Space.s8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._content(context, d),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, WageDetail d) {
    final l = context.l10n;
    final t = context.tokens;
    final r = d.row;
    String money(String v) => Fmt.money(v, decimals: true);

    return [
      AppCard(
        child: Row(
          children: [
            InitialsAvatar(r.name, size: 48),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: AppTypography.title.copyWith(color: t.textPrimary),
                  ),
                  Text(
                    l.wageText(r.wageType, r.wageAmount),
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            WageStatusPill(r.status),
          ],
        ),
      ),
      const SizedBox(height: Space.s3),
      LineItemSummaryCard(
        title: l.wageBreakdown,
        lines: [
          SummaryLine(
            l.workedDaysLine(
              '${r.presentDays}',
              '${r.halfDays}',
              '${r.absentDays}',
            ),
            daysText(l, r.workedDays),
          ),
          if (r.notMarkedDays > 0)
            SummaryLine(l.attNotMarked, '${r.notMarkedDays}'),
          SummaryLine(l.earned, money(r.earned), emphasis: true),
          SummaryLine(l.advances, '− ${money(r.advances)}'),
          SummaryLine(l.paid, '− ${money(r.paid)}', color: t.success),
          SummaryLine(
            l.balance,
            money(r.balance),
            emphasis: true,
            dividerBefore: true,
            color: r.hasBalance ? t.error : t.textTertiary,
          ),
        ],
      ),
      const SizedBox(height: Space.s3),
      Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _payWage,
            icon: const Icon(Icons.payments_outlined),
            label: Text(l.payWage),
          ),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _giveAdvance,
            icon: const Icon(Icons.request_quote_outlined),
            label: Text(l.giveAdvance),
          ),
        ],
      ),
      const SizedBox(height: Space.s3),
      _MoneyList(
        title: l.paymentsCount('${d.payments.length}'),
        empty: l.noWagePayments,
        rows: [
          for (final p in d.payments)
            _MoneyRow(
              icon: Icons.payments_outlined,
              color: t.success,
              title: '${Fmt.date(p.date)} · ${l.paymentMethodText(p.method)}',
              subtitle: [
                if ((p.note ?? '').isNotEmpty) p.note!,
                if (p.createdBy != null) l.byUser(p.createdBy!),
              ].join(' · '),
              amount: money(p.amount),
              deleteLabel: l.deletePayment,
              onDelete: _busy
                  ? null
                  : () => _delete(
                      title: l.deletePaymentTitle(money(p.amount)),
                      action: () =>
                          ref.read(wagesRepositoryProvider).deletePayment(p.id),
                    ),
            ),
        ],
      ),
      const SizedBox(height: Space.s3),
      _MoneyList(
        title: l.advancesCount('${d.advances.length}'),
        empty: l.noAdvances,
        rows: [
          for (final a in d.advances)
            _MoneyRow(
              icon: Icons.request_quote_outlined,
              color: t.warning,
              title: Fmt.date(a.date),
              subtitle: [
                if ((a.note ?? '').isNotEmpty) a.note!,
                if (a.createdBy != null) l.byUser(a.createdBy!),
              ].join(' · '),
              amount: money(a.amount),
              deleteLabel: l.deleteAdvance,
              onDelete: _busy
                  ? null
                  : () => _delete(
                      title: l.deleteAdvanceTitle(money(a.amount)),
                      action: () =>
                          ref.read(wagesRepositoryProvider).deleteAdvance(a.id),
                    ),
            ),
        ],
      ),
      const SizedBox(height: Space.s3),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(l.dayByDay, style: AppTypography.title),
              trailing: Icon(_showDays ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _showDays = !_showDays),
            ),
            if (_showDays)
              for (final day in d.days)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s4,
                    vertical: Space.s1,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          Fmt.date(day.date),
                          style: AppTypography.body.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.attendanceText(day.status),
                          style: AppTypography.caption.copyWith(
                            color: switch (day.status) {
                              'present' => t.success,
                              'half_day' => t.warning,
                              'absent' => t.error,
                              _ => t.textTertiary,
                            },
                          ),
                        ),
                      ),
                      Text(
                        money(day.earned),
                        style: AppTypography.body.copyWith(
                          color: t.textSecondary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
            if (_showDays) const SizedBox(height: Space.s3),
          ],
        ),
      ),
    ];
  }
}

class _MoneyList extends StatelessWidget {
  const _MoneyList({
    required this.title,
    required this.empty,
    required this.rows,
  });

  final String title;
  final String empty;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: Space.s2),
          if (rows.isEmpty)
            Text(
              empty,
              style: AppTypography.body.copyWith(color: t.textTertiary),
            ),
          ...rows,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.deleteLabel,
    required this.onDelete,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;
  final String deleteLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s1),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(color: t.textPrimary),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
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
            amount,
            style: AppTypography.bodyStrong.copyWith(
              color: color,
              fontFeatures: AppTypography.tabular,
            ),
          ),
          PopupMenuButton<void>(
            tooltip: deleteLabel,
            enabled: onDelete != null,
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: onDelete,
                child: Text(deleteLabel, style: TextStyle(color: t.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
