import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/network/api_client.dart';
import 'package:flyash/core/network/api_response.dart';
import 'package:flyash/core/network/data_changed.dart';
import 'package:flyash/core/network/optimistic.dart';
import 'package:flyash/core/network/query_cache.dart';

import '../fake_api.dart';
import 'api_client_test.dart' show setup;

void main() {
  group('DataTag', () {
    test('GET tags come from the path', () {
      expect(DataTag.of('/products'), {DataTag.products});
      expect(DataTag.of('/customers/7/sales'), {
        DataTag.customers,
        DataTag.sales,
      });
      expect(DataTag.of('/labours/1/wages'), {DataTag.labours, DataTag.wages});
      expect(DataTag.of('/expense-categories'), {DataTag.expenses});
      expect(DataTag.of('/reports/sales'), {DataTag.reports, DataTag.sales});
      expect(DataTag.of('/auth/me'), isEmpty, reason: 'never cached');
      expect(DataTag.of('/app/version'), isEmpty);
    });

    test('a write makes its dependants stale', () {
      expect(DataTag.affectedBy('/products/1/status'), {DataTag.products});
      expect(
        DataTag.affectedBy('/sales/5/payments'),
        containsAll([
          DataTag.sales,
          DataTag.customers,
          DataTag.dashboard,
          DataTag.reports,
        ]),
      );
      expect(
        DataTag.affectedBy('/attendance'),
        containsAll([
          DataTag.attendance,
          DataTag.labours,
          DataTag.wages,
          DataTag.dashboard,
        ]),
      );
      expect(DataTag.affectedBy('/wage-payments/3'), contains(DataTag.wages));
      expect(
        DataTag.affectedBy('/expenses'),
        isNot(contains(DataTag.sales)),
        reason: 'an expense never changes sales',
      );
    });
  });

  group('QueryCache', () {
    test('fresh for maxAge, then gone', () {
      var now = DateTime(2026, 11, 15, 10);
      final cache = QueryCache(
        maxAge: const Duration(seconds: 60),
        clock: () => now,
      );
      cache.write('k', {DataTag.sales}, {'data': 1});
      expect(cache.read('k'), {'data': 1});
      now = now.add(const Duration(seconds: 61));
      expect(cache.read('k'), isNull);
    });

    test('invalidate drops only entries with those tags', () {
      final cache = QueryCache()
        ..write('a', {DataTag.sales}, {})
        ..write('b', {DataTag.customers, DataTag.sales}, {})
        ..write('c', {DataTag.products}, {});
      cache.invalidate({DataTag.sales});
      expect(cache.read('a'), isNull);
      expect(cache.read('b'), isNull);
      expect(cache.read('c'), isNotNull);
    });
  });

  group('ApiClient cache', () {
    Future<(ApiClient, List<String>, dynamic)> client() async {
      final calls = <String>[];
      final (c, _) = await setup((o) {
        calls.add('${o.method} ${o.path}');
        return (200, envelope(200, 'ok', {'n': calls.length}), {});
      });
      return (c.read(apiClientProvider), calls, c);
    }

    Future<int> getN(ApiClient api, String path) async =>
        (await api.get(path, parse: (d) => (d as Json)['n'] as int)).data;

    test('a second GET comes from the cache; fresh() asks again', () async {
      final (api, calls, _) = await client();
      expect(await getN(api, '/products'), 1);
      expect(await getN(api, '/products'), 1, reason: 'cached');
      expect(calls, ['GET /products']);
      expect(await QueryCache.fresh(() => getN(api, '/products')), 2);
    });

    test('other query = other entry', () async {
      final (api, calls, _) = await client();
      await api.get('/sales', query: {'type': 'booking'}, parse: (d) => d);
      await api.get('/sales', query: {'type': 'instant'}, parse: (d) => d);
      expect(calls.length, 2);
    });

    test('a write drops the stale entries and bumps their tags only', () async {
      final (api, calls, c) = await client();
      await getN(api, '/customers');
      await getN(api, '/products');
      final before = c.read(dataChangedProvider) as DataVersions;
      await api.post('/sales', body: {}, parse: (d) => d);

      final after = c.read(dataChangedProvider) as DataVersions;
      expect(after.of(DataTag.sales), before.of(DataTag.sales) + 1);
      expect(after.of(DataTag.customers), before.of(DataTag.customers) + 1);
      expect(after.of(DataTag.products), before.of(DataTag.products));

      calls.clear();
      await getN(api, '/customers');
      await getN(api, '/products');
      expect(calls, ['GET /customers'], reason: 'products stayed cached');
    });

    test('auth calls are neither cached nor reported', () async {
      final (api, calls, c) = await client();
      await api.get('/auth/me', parse: (d) => d);
      await api.get('/auth/me', parse: (d) => d);
      await api.put('/auth/me', body: {}, parse: (d) => d);
      expect(calls.length, 3);
      expect(
        (c.read(dataChangedProvider) as DataVersions).sum([DataTag.users]),
        0,
      );
    });
  });

  group('optimistic patches', () {
    final t0 = DateTime(2026, 11, 15, 10);
    OptimisticPatch patch(Object? value, {bool removed = false}) =>
        OptimisticPatch(value, removed, t0.add(const Duration(seconds: 1)));

    test('newer patches replace or hide rows; older ones are ignored', () {
      final rows = ['a', 'b', 'c'];
      final patches = {'a': patch('A'), 'b': patch(null, removed: true)};
      expect(applyPatches(rows, patches, (r) => r, t0), ['A', 'c']);
      expect(
        applyPatches(
          rows,
          patches,
          (r) => r,
          t0.add(const Duration(seconds: 2)),
        ),
        rows,
        reason: 'loaded after the patch: the server data wins',
      );
    });
  });
}
