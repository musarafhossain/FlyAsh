import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../sales/presentation/sale_labels.dart';
import '../../data/wages_repository_impl.dart';
import '../../domain/wages.dart';

/// "26 days" (days present).
String daysText(AppLocalizations l, int presentDays) =>
    l.daysWorked(Fmt.count('$presentDays'));

/// Balance in red while something is owed; "—" when settled.
class BalanceText extends StatelessWidget {
  const BalanceText(this.row, {super.key, this.big = false});

  final WageRow row;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = big ? AppTypography.title : AppTypography.bodyStrong;
    return Text(
      row.hasBalance ? Fmt.money(row.balance) : '—',
      style: style.copyWith(
        color: row.hasBalance ? t.error : t.textTertiary,
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}

/// Pill for a wage status: Paid / Partial / Due.
class WageStatusPill extends StatelessWidget {
  const WageStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) => StatusPill(
    context.l10n.paymentStatusText(status),
    tone: StatusPill.toneFor(status),
  );
}

/// The "Wages" tab (03-AppFlow §7.3): ‹ month › (no future months), hero
/// with the month's total earned, Advances · Paid · Balance, search, and a
/// row per labour (days worked, earned, balance, status). Tap → the
/// labour's wage detail for that month.
class WagesTab extends ConsumerStatefulWidget {
  const WagesTab({super.key, this.initialMonth});

  /// From `?month=YYYY-MM`; default this month.
  final String? initialMonth;

  @override
  ConsumerState<WagesTab> createState() => _WagesTabState();
}

class _WagesTabState extends ConsumerState<WagesTab> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  late String _month = _validMonth(widget.initialMonth);
  WageTotals? _totals;

  String get _thisMonth => ref.read(businessDateProvider).substring(0, 7);

  String _validMonth(String? ym) {
    final now = ref.read(businessDateProvider).substring(0, 7);
    final ok = ym != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(ym);
    return ok && ym.compareTo(now) <= 0 ? ym : now;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  void _moveMonth(int by) {
    setState(() {
      _month = Ymd.addMonths('$_month-01', by).substring(0, 7);
      _totals = null;
    });
    _list.refresh();
  }

  Future<Paginated<WageRow>> _fetch(int page) async {
    final month = _month;
    final result = await ref
        .read(wagesRepositoryProvider)
        .sheet(month: month, page: page, search: _search.text);
    if (page == 1 && mounted && month == _month) {
      setState(
        () => _totals = WageTotals.fromJson(result.extra['totals'] as Json?),
      );
    }
    return result;
  }

  Future<void> _open(WageRow row) async {
    await context.push('/labours/wages/${row.labourId}?month=$_month');
    if (mounted) _list.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final totals = _totals;

    return PagedList<WageRow>(
      controller: _list,
      fetch: _fetch,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(
            label: Fmt.month(_month),
            onPrevious: () => _moveMonth(-1),
            onNext: _month.compareTo(_thisMonth) < 0
                ? () => _moveMonth(1)
                : null,
          ),
          const SizedBox(height: Space.s3),
          HeroCard(
            icon: Icons.payments_outlined,
            label: l.earnedInMonth(Fmt.month(_month)),
            value: totals == null ? '…' : Fmt.money(totals.earned),
          ),
          const SizedBox(height: Space.s2),
          KpiRow(
            children: [
              KpiChip(
                icon: Icons.request_quote_outlined,
                label: l.advances,
                value: totals == null ? '…' : Fmt.money(totals.advances),
                tint: KpiTint.amber,
              ),
              KpiChip(
                icon: Icons.check_circle_outline,
                label: l.paid,
                value: totals == null ? '…' : Fmt.money(totals.paid),
                tint: KpiTint.green,
              ),
              KpiChip(
                icon: Icons.account_balance_wallet_outlined,
                label: l.balance,
                value: totals == null ? '…' : Fmt.money(totals.balance),
                tint: KpiTint.rose,
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          TextField(
            controller: _search,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 350),
                _list.refresh,
              );
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.searchLabour,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ],
      ),
      empty: EmptyState(
        icon: Icons.payments_outlined,
        title: l.noWagesThisMonth,
        message: l.noWagesThisMonthMessage,
      ),
      builder: (context, rows) => desktop
          ? _WagesTable(rows: rows, onOpen: _open)
          : ListGroup(
              children: [
                for (final r in rows) _WageTile(row: r, onTap: () => _open(r)),
              ],
            ),
    );
  }
}

class _WageTile extends StatelessWidget {
  const _WageTile({required this.row, required this.onTap});

  final WageRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return ListRowSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          InitialsAvatar(row.name),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  '${daysText(l, row.presentDays)} · '
                  '${l.earnedAmount(Fmt.money(row.earned))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BalanceText(row),
              const SizedBox(height: Space.s1),
              WageStatusPill(row.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _WagesTable extends StatelessWidget {
  const _WagesTable({required this.rows, required this.onOpen});

  final List<WageRow> rows;
  final ValueChanged<WageRow> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DataTableCard(
      columns: [
        TableColumnDef(l.nameField, flex: 4),
        TableColumnDef(l.days, flex: 2, alignEnd: true),
        TableColumnDef(l.earned, flex: 2, alignEnd: true),
        TableColumnDef(l.advances, flex: 2, alignEnd: true),
        TableColumnDef(l.paid, flex: 2, alignEnd: true),
        TableColumnDef(l.balance, flex: 2, alignEnd: true),
        TableColumnDef(l.status, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final r in rows)
          [
            Row(
              children: [
                InitialsAvatar(r.name, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(r.name, strong: true)),
              ],
            ),
            CellText(Fmt.count('${r.presentDays}')),
            CellText(Fmt.money(r.earned)),
            CellText(Fmt.money(r.advances)),
            CellText(Fmt.money(r.paid)),
            BalanceText(r),
            WageStatusPill(r.status),
          ],
      ],
      onTapRow: (i) => onOpen(rows[i]),
    );
  }
}
