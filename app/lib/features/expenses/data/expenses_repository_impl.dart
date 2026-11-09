import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';
import '../domain/expense.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(this._api);

  final ApiClient _api;

  static Expense _expense(Object? d) => Expense.fromJson(d as Json);
  static ExpenseCategory _category(Object? d) =>
      ExpenseCategory.fromJson(d as Json);

  @override
  Future<Paginated<Expense>> list({
    int page = 1,
    DateRange range = const DateRange(),
    int? categoryId,
    String? search,
  }) => _api.getPage(
    '/expenses',
    page: page,
    query: {
      'from': range.from,
      'to': range.to,
      'category_id': categoryId,
      'search': search?.trim(),
    },
    item: Expense.fromJson,
  );

  @override
  Future<Expense> get(int id) async =>
      (await _api.get('/expenses/$id', parse: _expense)).data;

  @override
  Future<(Expense, String)> create(ExpenseInput input) async {
    final res = await _api.post(
      '/expenses',
      body: input.toJson(),
      parse: _expense,
    );
    return (res.data, res.message);
  }

  @override
  Future<(Expense, String)> update(int id, ExpenseInput input) async {
    final res = await _api.put(
      '/expenses/$id',
      body: input.toJson(),
      parse: _expense,
    );
    return (res.data, res.message);
  }

  @override
  Future<String> delete(int id) async =>
      (await _api.delete('/expenses/$id', parse: (d) => d)).message;

  @override
  Future<List<ExpenseCategory>> categories({bool? active}) async {
    final res = await _api.get(
      '/expense-categories',
      query: {'active': active},
      parse: (d) => [for (final c in d! as List<Object?>) _category(c)],
    );
    return res.data;
  }

  @override
  Future<ExpenseCategory> createCategory({
    required String name,
    String? icon,
  }) async => (await _api.post(
    '/expense-categories',
    body: {'name': name.trim(), 'icon': icon},
    parse: _category,
  )).data;

  @override
  Future<ExpenseCategory> updateCategory(
    int id, {
    required String name,
    String? icon,
    required bool isActive,
  }) async => (await _api.put(
    '/expense-categories/$id',
    body: {'name': name.trim(), 'icon': icon, 'is_active': isActive},
    parse: _category,
  )).data;
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryImpl(ref.watch(apiClientProvider)),
);
