import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flyash/core/config/preferences.dart';
import 'package:flyash/core/error/failure.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/network/api_client.dart';
import 'package:flyash/core/network/api_response.dart';
import 'package:flyash/core/network/session.dart';

import '../fake_api.dart';

Future<(ProviderContainer, FakeAdapter)> setup(
  Reply Function(RequestOptions) handler, {
  String? token,
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({'auth.token': ?token});
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore(const FlutterSecureStorage());
  await tokens.load();

  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
    ],
  );
  addTearDown(c.dispose);
  final adapter = FakeAdapter(handler);
  c.read(dioProvider).httpClientAdapter = adapter;
  return (c, adapter);
}

void main() {
  test('parses a single record and sends token + language headers', () async {
    final (c, adapter) = await setup(
      (_) => (
        200,
        envelope(200, 'Profile fetched successfully', {
          'id': 1,
          'name': 'Rahim',
        }),
        {},
      ),
      token: 'oat_abc',
    );
    await c.read(localeProvider.notifier).setLocale('bn');

    final res = await c
        .read(apiClientProvider)
        .get('/auth/me', parse: (d) => d as Json);

    expect(res.success, isTrue);
    expect(res.message, 'Profile fetched successfully');
    expect(res.data['name'], 'Rahim');
    expect(adapter.last!.headers['Authorization'], 'Bearer oat_abc');
    expect(adapter.last!.headers['Accept-Language'], 'bn');
  });

  test(
    'parses a paginated list with extra keys and sends page/limit',
    () async {
      final (c, adapter) = await setup(
        (_) => (
          200,
          envelope(200, 'ok', {
            'items': [
              {'id': 1},
              {'id': 2},
            ],
            'page': 1,
            'limit': 2,
            'total': 5,
            'last_page': 3,
            'period_total': '2050.50',
          }),
          {},
        ),
      );

      final page = await c
          .read(apiClientProvider)
          .getPage(
            '/expenses',
            limit: 2,
            query: {'category_id': null, 'active': true},
            item: (j) => j['id'] as int,
          );

      expect(page.items, [1, 2]);
      expect(page.hasMore, isTrue);
      expect(page.extra['period_total'], '2050.50');
      expect(adapter.last!.queryParameters, {
        'page': 1,
        'limit': 2,
        'active': 'true',
      });
    },
  );

  test(
    '422 becomes ValidationFailure with field errors and extra data',
    () async {
      final (c, _) = await setup(
        (_) => (
          422,
          envelope(422, 'Validation failed', {
            'errors': [
              {'field': 'phone', 'message': 'This phone belongs to Rahim'},
              {'field': 'phone', 'message': 'second message is ignored'},
              {'field': 'name', 'message': 'The name field is required'},
            ],
            'existing_customer_id': 12,
          }),
          {},
        ),
      );

      final future = c
          .read(apiClientProvider)
          .post('/customers', body: {}, parse: (d) => d);
      await expectLater(
        future,
        throwsA(
          isA<ValidationFailure>()
              .having((f) => f['phone'], 'phone', 'This phone belongs to Rahim')
              .having((f) => f.fieldErrors.length, 'fields', 2)
              .having(
                (f) => f.data?['existing_customer_id'],
                'existing id',
                12,
              ),
        ),
      );
    },
  );

  test(
    '400 business rule becomes ServerFailure with the server message',
    () async {
      final (c, _) = await setup(
        (_) => (
          400,
          envelope(400, 'Only a booked sale can be cancelled', null),
          {},
        ),
      );
      await expectLater(
        c.read(apiClientProvider).post('/sales/1/cancel', parse: (d) => d),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'Only a booked sale can be cancelled',
          ),
        ),
      );
    },
  );

  test(
    '401 with a token clears it and fires the session-expired signal',
    () async {
      final (c, _) = await setup(
        (_) => (401, envelope(401, 'Unauthorized', null), {}),
        token: 'oat_old',
      );

      await expectLater(
        c.read(apiClientProvider).get('/auth/me', parse: (d) => d),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(c.read(tokenStoreProvider).hasToken, isFalse);
      expect(c.read(sessionExpiredProvider), 1);
    },
  );

  test('a failed request without a token does not fire the signal', () async {
    final (c, _) = await setup(
      (_) => (401, envelope(401, 'Unauthorized', null), {}),
    );
    await expectLater(
      c.read(apiClientProvider).get('/auth/me', parse: (d) => d),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(c.read(sessionExpiredProvider), 0);
  });

  test('no connection becomes NetworkFailure', () async {
    final (c, _) = await setup(
      (o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      ),
    );
    await expectLater(
      c.read(apiClientProvider).get('/health', parse: (d) => d),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('X-Business-Date updates the factory date and is cached', () async {
    final (c, _) = await setup(
      (_) => (
        200,
        envelope(200, 'Healthy', {}),
        {'x-business-date': '2026-11-09'},
      ),
    );
    await c.read(apiClientProvider).get('/health', parse: (d) => d);

    expect(c.read(businessDateProvider), '2026-11-09');
    expect(
      c.read(sharedPreferencesProvider).getString('business.date'),
      '2026-11-09',
    );
  });

  test('Result.guard turns a Failure into Err', () async {
    final ok = await Result.guard(() async => 5);
    final err = await Result.guard<int>(
      () async => throw const NetworkFailure(),
    );
    expect(ok.when(ok: (v) => v, err: (_) => -1), 5);
    expect(
      err.when(ok: (v) => 'ok', err: (f) => f.message),
      'No internet connection',
    );
  });
}
