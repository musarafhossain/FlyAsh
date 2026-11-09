import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import 'expense_icons.dart';

/// Add a category, or rename it / change its icon / (de)activate it.
/// Pops with the saved [ExpenseCategory].
Future<ExpenseCategory?> showCategoryDialog(
  BuildContext context, {
  ExpenseCategory? category,
}) => showDialog<ExpenseCategory>(
  context: context,
  builder: (_) => _CategoryDialog(category: category),
);

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.category});

  final ExpenseCategory? category;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog>
    with FormSubmit {
  late final _name = TextEditingController(text: widget.category?.name);
  late String? _icon = widget.category?.icon ?? 'circle-dot';
  late bool _active = widget.category?.isActive ?? true;

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(expensesRepositoryProvider);
    late ExpenseCategory saved;
    final ok = await submit(() async {
      saved = _isEdit
          ? await repo.updateCategory(
              widget.category!.id,
              name: _name.text,
              icon: _icon,
              isActive: _active,
            )
          : await repo.createCategory(name: _name.text, icon: _icon);
    });
    if (ok && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    return AlertDialog(
      title: Text(_isEdit ? l.editCategory : l.newCategory),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: !_isEdit,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.sentences,
                  validator: v.required,
                  decoration: InputDecoration(
                    labelText: l.nameField,
                    hintText: l.categoryNameHint,
                    errorText: fieldErrors['name'],
                    counterText: '',
                  ),
                ),
                const SizedBox(height: Space.s3),
                Text(
                  l.icon,
                  style: AppTypography.label.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: Space.s2),
                Wrap(
                  spacing: Space.s2,
                  runSpacing: Space.s2,
                  children: [
                    for (final e in kExpenseIcons.entries)
                      Semantics(
                        button: true,
                        selected: _icon == e.key,
                        label: e.key,
                        child: InkWell(
                          borderRadius: Radii.mdAll,
                          onTap: () => setState(() => _icon = e.key),
                          child: Container(
                            width: kMinTouchTarget,
                            height: kMinTouchTarget,
                            decoration: BoxDecoration(
                              color: _icon == e.key
                                  ? t.primaryContainer
                                  : t.surfaceVariant,
                              borderRadius: Radii.mdAll,
                              border: Border.all(
                                color: _icon == e.key
                                    ? t.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              e.value,
                              color: _icon == e.key
                                  ? t.onPrimaryContainer
                                  : t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_isEdit) ...[
                  const SizedBox(height: Space.s3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.active),
                    subtitle: Text(l.inactiveCategoryHint),
                    value: _active,
                    onChanged: (x) => setState(() => _active = x),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: Space.s3),
                  FormErrorBanner(error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        BusyButton(label: l.save, busy: busy, onPressed: _save),
      ],
    );
  }
}
