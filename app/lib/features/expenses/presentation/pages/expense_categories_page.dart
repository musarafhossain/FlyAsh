import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/expenses_repository_impl.dart';
import '../../domain/expense.dart';
import '../widgets/category_dialog.dart';
import '../widgets/expense_icons.dart';
import 'expenses_list_page.dart' show activeExpenseCategoriesProvider;

/// All expense categories (active and inactive): add, rename, change the
/// icon, deactivate / activate. Categories are never deleted.
class ExpenseCategoriesPage extends ConsumerStatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  ConsumerState<ExpenseCategoriesPage> createState() =>
      _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends ConsumerState<ExpenseCategoriesPage> {
  List<ExpenseCategory>? _categories;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await ref.read(expensesRepositoryProvider).categories();
      if (mounted) setState(() => _categories = list);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit([ExpenseCategory? category]) async {
    final saved = await showCategoryDialog(context, category: category);
    if (saved == null || !mounted) return;
    final l = context.l10n;
    showMessage(
      context,
      category == null ? l.categoryCreated : l.categoryUpdated,
    );
    ref.invalidate(activeExpenseCategoriesProvider);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final list = _categories;
    return Scaffold(
      appBar: AppBar(title: Text(l.manageCategories)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l.newCategory),
      ),
      body: list == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const Padding(
                    padding: EdgeInsets.all(Space.s4),
                    child: SkeletonList(),
                  ))
          : PageBody(
              children: [
                Text(
                  l.categoriesHint,
                  style: AppTypography.caption.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: Space.s3),
                for (final c in list) ...[
                  Opacity(
                    opacity: c.isActive ? 1 : 0.6,
                    child: AppCard(
                      onTap: () => _edit(c),
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
                          if (!c.isActive) StatusPill(l.inactive),
                          Icon(Icons.edit_outlined, color: t.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.s2),
                ],
                const SizedBox(height: Space.s10),
              ],
            ),
    );
  }
}
