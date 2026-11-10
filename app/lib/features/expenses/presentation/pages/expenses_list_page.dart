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
import '../../../sales/presentation/widgets/sale_filter_sheet.dart'
    show presetText;
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import '../widgets/expense_icons.dart';

/// Active categories (chips, form picker). Invalidate after changes.
final activeExpenseCategoriesProvider = FutureProvider<List<ExpenseCategory>>(
  (ref) => ref.watch(expensesRepositoryProvider).categories(active: true),
);

/// Expenses (03-AppFlow §8): period (Today … Last month, Custom; default
/// this month), the period total, category chips, search by note, and
/// expense rows. Cards on phones/tablets, a table on desktop. Tap → edit.
class ExpensesListPage extends ConsumerStatefulWidget {
  const ExpensesListPage({super.key});

  @override
  ConsumerState<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends ConsumerState<ExpensesListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  DatePreset _preset = DatePreset.thisMonth;
  late DateRange _range = DateRange.preset(
    DatePreset.thisMonth,
    ref.read(businessDateProvider),
  );
  String? _categoryId;
  String? _periodTotal;

  String get _today => ref.read(businessDateProvider);

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _periodTotal = null);
    _list.refresh();
  }

  Future<void> _choosePreset(DatePreset preset) async {
    if (preset != DatePreset.custom) {
      setState(() {
        _preset = preset;
        _range = DateRange.preset(preset, _today);
      });
      _reload();
      return;
    }
    DateTime local(String ymd) {
      final d = Ymd.parse(ymd);
      return DateTime(d.year, d.month, d.day);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: local(_today),
      initialDateRange: DateTimeRange(
        start: local(_range.from ?? _today),
        end: local(_range.to ?? _today),
      ),
    );
    if (picked == null) return;
    String ymd(DateTime d) => Ymd.format(DateTime.utc(d.year, d.month, d.day));
    setState(() {
      _preset = DatePreset.custom;
      _range = DateRange(from: ymd(picked.start), to: ymd(picked.end));
    });
    _reload();
  }

  Future<Paginated<Expense>> _fetch(int page) async {
    final range = _range;
    final result = await ref
        .read(expensesRepositoryProvider)
        .list(
          page: page,
          range: range,
          categoryId: _categoryId,
          search: _search.text,
        );
    if (page == 1 && mounted && range == _range) {
      setState(() => _periodTotal = '${result.extra['period_total'] ?? '0'}');
    }
    return result;
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (!mounted) return;
    ref.invalidate(activeExpenseCategoriesProvider);
    _reload();
  }

  String _periodLabel(AppLocalizations l) {
    if (_preset != DatePreset.custom) return presetText(l, _preset);
    if (_range.from == _range.to) return Fmt.date(_range.from);
    return '${Fmt.date(_range.from)} – ${Fmt.date(_range.to)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final categories = ref.watch(activeExpenseCategoriesProvider).value ?? [];
    final filtered = _categoryId != null || _search.text.trim().isNotEmpty;

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
        controller: _list,
        fetch: _fetch,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in [
                    DatePreset.today,
                    DatePreset.thisWeek,
                    DatePreset.thisMonth,
                    DatePreset.lastMonth,
                    DatePreset.custom,
                  ]) ...[
                    ChoiceChip(
                      avatar: p == DatePreset.custom
                          ? const Icon(Icons.date_range, size: 18)
                          : null,
                      label: Text(
                        p == DatePreset.custom && _preset == p
                            ? _periodLabel(l)
                            : presetText(l, p),
                      ),
                      selected: _preset == p,
                      onSelected: (_) => _choosePreset(p),
                    ),
                    const SizedBox(width: Space.s2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.s3),
            HeroCard(
              icon: Icons.receipt_long_outlined,
              label: l.spentIn(_periodLabel(l)),
              value: _periodTotal == null ? '…' : Fmt.money(_periodTotal),
            ),
            ...[
              const SizedBox(height: Space.s3),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(l.allCategories),
                      selected: _categoryId == null,
                      onSelected: (_) {
                        setState(() => _categoryId = null);
                        _reload();
                      },
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: Space.s2),
                      ChoiceChip(
                        avatar: Icon(expenseIcon(c.icon), size: 18),
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) {
                          setState(() => _categoryId = c.id);
                          _reload();
                        },
                      ),
                    ],
                    const SizedBox(width: Space.s2),
                    ActionChip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: Text(l.manageCategories),
                      tooltip: l.manageCategories,
                      onPressed: () => _open('/expenses/categories'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Space.s3),
            TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), _reload);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchNote,
                prefixIcon: const Icon(Icons.search),
              ),
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
                children: [
                  for (final e in expenses)
                    ExpenseTile(
                      expense: e,
                      onTap: () => _open('/expenses/${e.id}/edit'),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Row: category icon · note (or category) · date · category | amount.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onTap});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final e = expense;
    final hasNote = (e.note ?? '').isNotEmpty;
    return ListRowSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          ExpenseIcon(e.categoryIcon),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasNote ? e.note! : (e.categoryName ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  [
                    Fmt.date(e.date),
                    if (hasNote && e.categoryName != null) e.categoryName!,
                  ].join(' · '),
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
                ExpenseIcon(e.categoryIcon, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(e.categoryName ?? '—', strong: true)),
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
