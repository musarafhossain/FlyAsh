import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import '../widgets/category_dialog.dart';
import '../widgets/expense_icons.dart';
import '../../../../core/widgets/skeletons.dart';
import 'expenses_list_page.dart' show activeExpenseCategoriesProvider;

/// Add or edit an expense (03-AppFlow §8): date (not future), category
/// (sheet with "+ New category"), amount, note. Edit has ⋮ Delete.
/// Pops with true when something changed.
class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key, this.expenseId});

  /// Null = add a new expense.
  final String? expenseId;

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage>
    with FormSubmit {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _date = ref.read(businessDateProvider);
  ExpenseCategory? _category;
  bool _categoryMissing = false;
  bool _loaded = false;
  Object? _loadError;

  bool get _isEdit => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final e = await ref
          .read(expensesRepositoryProvider)
          .get(widget.expenseId!);
      if (!mounted) return;
      setState(() {
        _date = e.date;
        _amount.text = (Decimal.tryParse(e.amount) ?? Decimal.zero).toString();
        _note.text = e.note ?? '';
        _category = ExpenseCategory(
          id: e.categoryId,
          name: e.categoryName ?? '',
          icon: e.categoryIcon,
        );
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _CategorySheet(),
    );
    if (picked != null) {
      setState(() {
        _category = picked;
        _categoryMissing = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _categoryMissing = _category == null);
    if (_category == null) {
      formKey.currentState?.validate();
      return;
    }
    final repo = ref.read(expensesRepositoryProvider);
    final input = ExpenseInput(
      categoryId: _category!.id,
      date: _date,
      amount: _amount.text.trim(),
      note: textOrNull(_note),
    );
    late String message;
    final ok = await submit(() async {
      final (_, msg) = _isEdit
          ? await repo.update(widget.expenseId!, input)
          : await repo.create(input);
      message = msg;
    });
    if (!ok || !mounted) return;
    showMessage(context, message);
    context.pop(true);
  }

  Future<void> _delete() async {
    final l = context.l10n;
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
          .delete(widget.expenseId!);
      if (!mounted) return;
      showMessage(context, message);
      context.pop(true);
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    final today = ref.read(businessDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l.editExpense : l.addExpense),
        actions: [
          if (_isEdit && _loaded)
            IconButton(
              tooltip: l.delete,
              onPressed: busy ? null : _delete,
              icon: Icon(Icons.delete_outline, color: t.error),
            ),
        ],
      ),
      body: !_loaded
          ? (_loadError != null
                ? ErrorState(
                    message: failureText(context, _loadError!),
                    onRetry: _load,
                  )
                : const FormSkeleton(fields: 4, big: {3}))
          : Form(
              key: formKey,
              child: PageBody(
                children: [
                  DateField(
                    label: l.date,
                    value: _date,
                    first: '2020-01-01',
                    last: today,
                    errorText: fieldErrors['expense_date'],
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  const SizedBox(height: Space.s3),
                  Semantics(
                    button: true,
                    label: l.category,
                    child: InkWell(
                      borderRadius: Radii.mdAll,
                      onTap: _pickCategory,
                      child: InputDecorator(
                        isEmpty: _category == null,
                        decoration: InputDecoration(
                          labelText: l.category,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(Space.s2),
                            child: _category == null
                                ? const Icon(Icons.category_outlined)
                                : ExpenseIcon(_category!.icon, size: 32),
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          errorText: _categoryMissing
                              ? l.selectCategoryError
                              : fieldErrors['expense_category_id'],
                        ),
                        child: _category == null
                            ? null
                            : Text(
                                _category!.name,
                                style: AppTypography.body.copyWith(
                                  color: t.textPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  MoneyField(
                    controller: _amount,
                    label: l.amount,
                    validator: (x) {
                      final e = v.money(x);
                      if (e != null) return e;
                      return Decimal.parse(x!.trim()) > Decimal.zero
                          ? null
                          : l.invalidAmount;
                    },
                    errorText: fieldErrors['amount'],
                  ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l.notesOptional,
                      hintText: l.expenseNoteHint,
                      errorText: fieldErrors['note'],
                    ),
                  ),
                  const SizedBox(height: Space.s4),
                  if (error != null) ...[
                    FormErrorBanner(error!),
                    const SizedBox(height: Space.s3),
                  ],
                  BusyButton(
                    label: _isEdit ? l.save : l.addExpense,
                    busy: busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Active categories to choose from, "+ New category" and
/// "Manage categories". Pops with the chosen category.
class _CategorySheet extends ConsumerWidget {
  const _CategorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final async = ref.watch(activeExpenseCategoriesProvider);

    Future<void> addNew() async {
      final created = await showCategoryDialog(context);
      if (created == null) return;
      ref.invalidate(activeExpenseCategoriesProvider);
      if (context.mounted) Navigator.of(context).pop(created);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.selectCategory,
              style: AppTypography.h3.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: Space.s3),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Space.s4),
                  child: SkeletonList(count: 4),
                ),
                error: (e, _) => ErrorState(
                  message: failureText(context, e),
                  onRetry: () =>
                      ref.invalidate(activeExpenseCategoriesProvider),
                ),
                data: (categories) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in categories) ...[
                      AppCard(
                        onTap: () => Navigator.of(context).pop(c),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s3,
                          vertical: Space.s2,
                        ),
                        child: Row(
                          children: [
                            ExpenseIcon(c.icon, size: 36),
                            const SizedBox(width: Space.s3),
                            Expanded(
                              child: Text(
                                c.name,
                                style: AppTypography.body.copyWith(
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.s2),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.s2),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: addNew,
                    icon: const Icon(Icons.add),
                    label: Text(l.newCategory),
                  ),
                ),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/expenses/categories');
                    },
                    icon: const Icon(Icons.tune),
                    label: Text(l.manageCategories),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
