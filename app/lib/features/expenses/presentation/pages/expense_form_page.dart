import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import '../widgets/expense_icons.dart';
import '../../../../core/widgets/skeletons.dart';

/// Add or edit an expense (03-AppFlow §8): date (not future), category
/// (any text; earlier categories are suggested as chips), amount, note.
/// Edit has a Delete button. Pops with true when something changed.
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
  final _category = TextEditingController();
  late String _date = ref.read(businessDateProvider);
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
    _category.dispose();
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
        _category.text = e.category;
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final repo = ref.read(expensesRepositoryProvider);
    final input = ExpenseInput(
      category: _category.text.trim().replaceAll(RegExp(r'\s+'), ' '),
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
                  _CategoryField(
                    controller: _category,
                    validator: v.required,
                    errorText: fieldErrors['category'],
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

/// Category: a text field for any category, with earlier ones (most
/// used first) as chips below; tapping a chip fills the field. The chips
/// follow what is typed.
class _CategoryField extends ConsumerStatefulWidget {
  const _CategoryField({
    required this.controller,
    required this.validator,
    this.errorText,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String? errorText;

  @override
  ConsumerState<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends ConsumerState<_CategoryField> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final typed = widget.controller.text.trim().toLowerCase();
    final all = ref.watch(expenseCategoriesProvider).value ?? const [];
    final shown = [
      for (final c in all)
        if (c.toLowerCase().contains(typed) && c.toLowerCase() != typed) c,
    ].take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: l.category,
            hintText: l.categoryHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(Space.s2),
              child: typed.isEmpty
                  ? const Icon(Icons.sell_outlined)
                  : ExpenseIcon(widget.controller.text, size: 32),
            ),
            counterText: '',
            errorText: widget.errorText,
          ),
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: Space.s2),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              for (final c in shown)
                ActionChip(
                  avatar: Icon(expenseIcon(c), size: 18),
                  label: Text(c),
                  onPressed: () => setState(() {
                    widget.controller.text = c;
                    widget.controller.selection = TextSelection.collapsed(
                      offset: c.length,
                    );
                  }),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
