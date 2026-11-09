import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';

/// A kind of expense (Labour Tiffin, Machine Repair …). Never deleted;
/// deactivated instead (07-API §13).
@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    this.icon,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final int id;
  final String name;

  /// Icon key, e.g. "wrench" (see expense_icons.dart).
  final String? icon;
  final bool isActive;
  final int sortOrder;

  factory ExpenseCategory.fromJson(Json json) => ExpenseCategory(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    icon: json['icon'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );
}

/// Money spent on a date in a category.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.categoryId,
    required this.date,
    required this.amount,
    this.note,
    this.categoryName,
    this.categoryIcon,
    this.createdBy,
  });

  final int id;
  final int categoryId;
  final String date;
  final String amount;
  final String? note;
  final String? categoryName;
  final String? categoryIcon;
  final String? createdBy;

  factory Expense.fromJson(Json json) {
    final category = json['category'] as Json?;
    return Expense(
      id: (json['id'] as num).toInt(),
      categoryId: (json['expense_category_id'] as num?)?.toInt() ?? 0,
      date: json['expense_date'] as String? ?? '',
      amount: '${json['amount'] ?? '0'}',
      note: json['note'] as String?,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      createdBy: (json['created_by'] as Json?)?['name'] as String?,
    );
  }
}

/// What the expense form sends. Money is a decimal string.
@immutable
class ExpenseInput {
  const ExpenseInput({
    required this.categoryId,
    required this.date,
    required this.amount,
    this.note,
  });

  final int categoryId;
  final String date;
  final String amount;
  final String? note;

  Json toJson() => {
    'expense_category_id': categoryId,
    'expense_date': date,
    'amount': amount,
    'note': note,
  };
}

/// Expenses API (07-API §13). Methods throw a `Failure` on error.
abstract interface class ExpensesRepository {
  /// GET /expenses?page&from&to&category_id&search (newest first);
  /// `extra['period_total']` is the total of the whole filtered range.
  Future<Paginated<Expense>> list({
    int page = 1,
    DateRange range = const DateRange(),
    int? categoryId,
    String? search,
  });

  Future<Expense> get(int id);

  Future<(Expense, String)> create(ExpenseInput input);

  Future<(Expense, String)> update(int id, ExpenseInput input);

  /// DELETE /expenses/:id → message
  Future<String> delete(int id);

  /// GET /expense-categories?active (sorted, not paginated)
  Future<List<ExpenseCategory>> categories({bool? active});

  Future<ExpenseCategory> createCategory({required String name, String? icon});

  /// Rename, change the icon, or deactivate / activate.
  Future<ExpenseCategory> updateCategory(
    int id, {
    required String name,
    String? icon,
    required bool isActive,
  });
}
