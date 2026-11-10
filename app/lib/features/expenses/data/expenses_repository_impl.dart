import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/data_changed.dart';
import '../../../core/utils/dates.dart';
import '../domain/expense.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(this._api);

  final ApiClient _api;

  static Expense _expense(Object? d) => Expense.fromJson(d as Json);

  @override
  Future<Paginated<Expense>> list({
    int page = 1,
    DateRange range = const DateRange(),
    String? category,
    String? search,
  }) => _api.getPage(
    '/expenses',
    page: page,
    query: {
      'from': range.from,
      'to': range.to,
      'category': category,
      'search': search?.trim(),
    },
    item: Expense.fromJson,
  );

  @override
  Future<Expense> get(String id) async =>
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
  Future<(Expense, String)> update(String id, ExpenseInput input) async {
    final res = await _api.put(
      '/expenses/$id',
      body: input.toJson(),
      parse: _expense,
    );
    return (res.data, res.message);
  }

  @override
  Future<String> delete(String id) async =>
      (await _api.delete('/expenses/$id', parse: (d) => d)).message;

  @override
  Future<List<String>> categories() async => (await _api.get(
    '/expense-categories',
    parse: (d) => [for (final c in d! as List<Object?>) '$c'],
  )).data;
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Category names for suggestions and the filter. Loads again after any
/// change (a new category typed in an expense shows up next time).
final expenseCategoriesProvider = FutureProvider<List<String>>((ref) {
  ref.watch(dataChangedProvider);
  return ref.watch(expensesRepositoryProvider).categories();
});
