import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/session.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/network/data_changed.dart';
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import '../widgets/expense_filter_sheet.dart';
import '../widgets/expense_icons.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/error/failure.dart';

/// Expenses (03-AppFlow §8): search, a filter button (period, default
/// this month, and category) with the active filters as chips, the period
/// total, and expense rows. A table on desktop. Tap → edit.
class ExpensesListPage extends ConsumerStatefulWidget {
  const ExpensesListPage({super.key});

  @override
  ConsumerState<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends ConsumerState<ExpensesListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  late ExpenseFilter _filter = ExpenseFilter.initial(_today);
  String? _periodTotal;

  /// True while page 1 (which carries the period total) is loading.
  bool _totalLoading = true;

  String get _today => ref.read(businessDateProvider);

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _periodTotal = null;
      _totalLoading = true;
    });
    _list.refresh();
  }

  void _apply(ExpenseFilter filter) {
    setState(() => _filter = filter);
    _reload();
  }

  Future<void> _openFilters() async {
    final next = await showExpenseFilterSheet(
      context,
      filter: _filter,
      categories: ref.read(expenseCategoriesProvider).value ?? const [],
      today: _today,
    );
    if (next != null) _apply(next);
  }

  Future<Paginated<Expense>> _fetch(int page) async {
    final filter = _filter;
    try {
      final result = await ref
          .read(expensesRepositoryProvider)
          .list(
            page: page,
            range: filter.range,
            category: filter.category,
            search: _search.text,
          );
      if (page == 1 && mounted && filter == _filter) {
        setState(() => _periodTotal = '${result.extra['period_total'] ?? '0'}');
      }
      return result;
    } finally {
      // Loaded or failed: stop the placeholder (a failure shows "—").
      if (page == 1 && mounted && filter == _filter) {
        setState(() => _totalLoading = false);
      }
    }
  }

  Future<void> _open(String location) async {
    await context.push(location);
  }

  /// Long press: Edit | Delete. The list reloads by itself after a change.
  Future<void> _actions(BuildContext row, Expense e) {
    final l = context.l10n;
    return showActionMenu(
      row,
      groups: [
        [
          ActionMenuItem(
            icon: Icons.edit_outlined,
            label: l.edit,
            onSelected: () => _open('/expenses/${e.id}/edit'),
          ),
        ],
        [
          ActionMenuItem(
            icon: Icons.delete_outline,
            label: l.delete,
            destructive: true,
            onSelected: () async {
              final ok = await showConfirmDialog(
                context,
                title: l.deleteExpenseTitle,
                message: l.deleteExpenseMessage,
                confirmLabel: l.delete,
                destructive: true,
              );
              if (!ok || !mounted) return;
              try {
                final message = await ref
                    .read(expensesRepositoryProvider)
                    .delete(e.id);
                if (mounted) showMessage(context, message);
              } on Failure catch (f) {
                if (mounted) showMessage(context, failureText(context, f));
              }
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    ref.listen(dataChangedProvider, (_, _) => _reload());
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    ref.watch(expenseCategoriesProvider); // ready for the filter sheet
    final filtered = _filter.category != null || _search.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navExpenses),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/expenses/new'),
        icon: const Icon(Icons.add),
        label: Text(l.addExpense),
      ),
      body: PagedList<Expense>(
        showCount: false,
        controller: _list,
        fetch: _fetch,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 350),
                        _reload,
                      );
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchNote,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s2),
                Badge.count(
                  count: _filter.activeCount,
                  isLabelVisible: _filter.activeCount > 0,
                  child: IconButton.outlined(
                    tooltip: l.filterExpenses,
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            if (_filter.activeCount > 0) ...[
              const SizedBox(height: Space.s2),
              Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  if (_filter.preset != DatePreset.thisMonth)
                    InputChip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(_filter.periodText(l)),
                      onPressed: _openFilters,
                      onDeleted: () => _apply(
                        _filter.copyWith(
                          preset: DatePreset.thisMonth,
                          range: DateRange.preset(DatePreset.thisMonth, _today),
                        ),
                      ),
                    ),
                  if (_filter.category != null)
                    InputChip(
                      avatar: const Icon(Icons.sell_outlined, size: 18),
                      label: Text(_filter.category!),
                      onPressed: _openFilters,
                      onDeleted: () =>
                          _apply(_filter.copyWith(category: () => null)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Space.s3),
            HeroCard(
              icon: Icons.receipt_long_outlined,
              label: l.spentIn(_filter.periodText(l)),
              value: _periodTotal == null ? '—' : Fmt.money(_periodTotal),
              loading: _periodTotal == null && _totalLoading,
            ),
          ],
        ),
        empty: filtered
            ? EmptyState(icon: Icons.search_off, title: l.noResults)
            : EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l.noExpenses,
                message: l.noExpensesMessage,
                actionLabel: l.addExpense,
                onAction: () => _open('/expenses/new'),
              ),
        builder: (context, expenses) => desktop
            ? _ExpensesTable(
                expenses: expenses,
                onOpen: (e) => _open('/expenses/${e.id}/edit'),
              )
            : ListGroup(
                flat: true,
                children: [
                  for (final e in expenses)
                    ExpenseTile(
                      expense: e,
                      onTap: () => _open('/expenses/${e.id}/edit'),
                      onLongPress: (row) => _actions(row, e),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Row: category icon · note (or category) · date · category | amount.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onLongPress,
  });

  final Expense expense;
  final VoidCallback? onTap;

  /// Opens the action menu next to this row (gets the row's context).
  final ValueChanged<BuildContext>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = expense;
    final hasNote = (e.note ?? '').isNotEmpty;
    return ListRowSurface(
      onTap: onTap,
      onLongPress: onLongPress == null ? null : () => onLongPress!(context),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          ExpenseIcon(e.category),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasNote ? e.note! : e.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  [Fmt.date(e.date), if (hasNote) e.category].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s2),
          Text(
            Fmt.money(e.amount),
            style: AppTypography.bodyStrong.copyWith(
              color: t.textPrimary,
              fontFeatures: AppTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTable extends StatelessWidget {
  const _ExpensesTable({required this.expenses, required this.onOpen});

  final List<Expense> expenses;
  final ValueChanged<Expense> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DataTableCard(
      columns: [
        TableColumnDef(l.date, flex: 2),
        TableColumnDef(l.category, flex: 3),
        TableColumnDef(l.note, flex: 4),
        TableColumnDef(l.enteredByColumn, flex: 2),
        TableColumnDef(l.amount, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final e in expenses)
          [
            CellText(Fmt.date(e.date)),
            Row(
              children: [
                ExpenseIcon(e.category, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(e.category, strong: true)),
              ],
            ),
            CellText(e.note ?? '—'),
            CellText(e.createdBy ?? '—'),
            CellText(Fmt.money(e.amount), strong: true),
          ],
      ],
      onTapRow: (i) => onOpen(expenses[i]),
    );
  }
}
