import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/data_changed.dart';
import '../../../../core/network/optimistic.dart';
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
import '../widgets/wage_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/action_menu.dart';
import '../widgets/lifetime_wage_card.dart';
import '../../../../core/widgets/motion.dart';

/// A labour's wage for a month (03-AppFlow §7.3): breakdown
/// worked days × rate − paid = balance, ⋮ → Pay wage, the payments (an
/// advance is just an early payment; long press → Delete), and the
/// day-by-day list. Pull to refresh.
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
    final deleted = await confirmDelete(
      context,
      title: title,
      message: l.balanceRecalculated,
      delete: action,
    );
    if (deleted && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    // Reload in the background when this data changes anywhere.
    ref.onDataChanged({
      DataTag.wages,
      DataTag.attendance,
    }, () => unawaited(_load()));
    final l = context.l10n;
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.row.name ?? l.wageDetails),
        actions: [
          if (d != null)
            ActionMenuButton(
              tooltip: l.moreActions,
              enabled: !_busy,
              groups: [
                [
                  ActionMenuItem(
                    icon: Icons.payments_outlined,
                    label: l.payWage,
                    onSelected: _payWage,
                  ),
                ],
              ],
            ),
        ],
      ),
      body: PageBody(
        maxWidth: 760,
        onRefresh: _load,
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonHeader(),
                SizedBox(height: Space.s3),
                SkeletonLines(count: 6, title: true),
                SizedBox(height: Space.s3),
                SkeletonLines(count: 2, title: true),
                SizedBox(height: Space.s3),
                SkeletonLines(count: 2, title: true),
              ],
            )
          else
            ..._content(context, d),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, WageDetail d) {
    final payments = [
      for (final p in d.payments)
        if (!ref.isRemoved(p.id)) p,
    ];
    final l = context.l10n;
    final t = context.tokens;
    final r = d.row;
    String money(String v) => Fmt.money(v);

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
            l.workedDaysLine('${r.presentDays}', '${r.absentDays}'),
            daysText(l, r.presentDays),
          ),
          SummaryLine(l.earned, money(r.earned), emphasis: true),
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
      DetailSection(
        title: l.paymentsCount('${payments.length}'),
        empty: l.noWagePayments,
        children: [
          for (final p in payments)
            DetailRow(
              leading: PaymentAvatar(paymentMethodIcon(p.method)),
              title: '${Fmt.date(p.date)} · ${l.paymentMethodText(p.method)}',
              subtitle: [
                if ((p.note ?? '').isNotEmpty) p.note!,
                if (p.createdBy != null) l.byUser(p.createdBy!),
              ].join(' · '),
              amount: money(p.amount),
              amountColor: t.success,
              onLongPress: _busy
                  ? null
                  : (row) => showActionMenu(
                      row,
                      groups: [
                        [
                          ActionMenuItem(
                            icon: Icons.delete_outline,
                            label: l.deletePayment,
                            destructive: true,
                            onSelected: () => _delete(
                              title: l.deletePaymentTitle(money(p.amount)),
                              action: () => ref
                                  .read(wagesRepositoryProvider)
                                  .deletePayment(p.id),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
        ],
      ),
      const SizedBox(height: Space.s3),
      _DayByDay(
        days: d.days,
        open: _showDays,
        onToggle: () => setState(() => _showDays = !_showDays),
      ),
      if (d.lifetime != null) ...[
        const SizedBox(height: Space.s3),
        LifetimeWageCard(
          earned: d.lifetime!.earned,
          paid: d.lifetime!.paid,
          balance: d.lifetime!.balance,
        ),
      ],
    ];
  }
}

/// "Day by day": a header with an arrow that turns, and the list sliding
/// open / closed below it.
class _DayByDay extends StatelessWidget {
  const _DayByDay({
    required this.days,
    required this.open,
    required this.onToggle,
  });

  final List<WageDay> days;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final duration = Motion.reduced(context) ? Duration.zero : Motion.base;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('dayByDayHeader'),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s4,
                vertical: Space.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.dayByDay,
                      style: AppTypography.title.copyWith(color: t.textPrimary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: duration,
                    curve: Motion.standard,
                    child: Icon(Icons.expand_more, color: t.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: duration,
              curve: Motion.standard,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: Space.s3),
                      child: Column(
                        children: [
                          for (final day in days)
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
                                      l.attendanceText(true),
                                      style: AppTypography.caption.copyWith(
                                        color: t.success,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Fmt.money(day.earned),
                                    style: AppTypography.body.copyWith(
                                      color: t.textSecondary,
                                      fontFeatures: AppTypography.tabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
