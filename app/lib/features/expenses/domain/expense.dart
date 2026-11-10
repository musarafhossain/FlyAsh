import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';

/// Money spent on a date. [category] is plain text typed by the user
/// ("Labour Tiffin", "Generator rent" …), not a link to a list.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.date,
    required this.amount,
    this.note,
    this.createdBy,
  });

  final String id;
  final String category;
  final String date;
  final String amount;
  final String? note;
  final String? createdBy;

  factory Expense.fromJson(Json json) => Expense(
    id: idOf(json['id']),
    category: json['category'] as String? ?? '',
    date: json['expense_date'] as String? ?? '',
    amount: '${json['amount'] ?? '0'}',
    note: json['note'] as String?,
    createdBy: (json['created_by'] as Json?)?['name'] as String?,
  );
}

/// What the expense form sends. Money is a decimal string.
@immutable
class ExpenseInput {
  const ExpenseInput({
    required this.category,
    required this.date,
    required this.amount,
    this.note,
  });

  final String category;
  final String date;
  final String amount;
  final String? note;

  Json toJson() => {
    'category': category.trim(),
    'expense_date': date,
    'amount': amount,
    'note': note,
  };
}

/// Expenses API (07-API §13). Methods throw a `Failure` on error.
abstract interface class ExpensesRepository {
  /// GET /expenses?page&from&to&category&search (newest first);
  /// `extra['period_total']` is the total of the whole filtered range.
  Future<Paginated<Expense>> list({
    int page = 1,
    DateRange range = const DateRange(),
    String? category,
    String? search,
  });

  Future<Expense> get(String id);

  Future<(Expense, String)> create(ExpenseInput input);

  Future<(Expense, String)> update(String id, ExpenseInput input);

  /// DELETE /expenses/:id → message
  Future<String> delete(String id);

  /// GET /expense-categories → names used before (most used first), then
  /// common ones. Suggestions and filter choices only.
  Future<List<String>> categories();
}
