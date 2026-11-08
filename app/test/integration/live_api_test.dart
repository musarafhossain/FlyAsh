// Runs against the real API (backend must be running).
//   flutter test test/integration --dart-define=LIVE_API=true
// Optional: --dart-define=API_BASE_URL=... --dart-define=LIVE_LOGIN=... --dart-define=LIVE_PASSWORD=...
@TestOn('vm')
library;

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

const live = bool.fromEnvironment('LIVE_API');
const login = String.fromEnvironment('LIVE_LOGIN', defaultValue: '9876543210');
const password = String.fromEnvironment(
  'LIVE_PASSWORD',
  defaultValue: 'secret123',
);

void main() {
  late ProviderContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = TokenStore(const FlutterSecureStorage());
    c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
    );
  });
  tearDown(() => c.dispose());

  test('health + factory date header', () async {
    final res = await c
        .read(apiClientProvider)
        .get('/health', parse: (d) => d as Json);
    expect(res.data['status'], 'ok');
    expect(
      c.read(businessDateProvider),
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
    );
  }, skip: !live);

  test('wrong password: translated ServerFailure (en and bn)', () async {
    final api = c.read(apiClientProvider);
    Future<Object?> attempt() => api.post(
      '/auth/login',
      body: {'login': login, 'password': 'wrong-password'},
      parse: (d) => d,
    );

    await expectLater(
      attempt(),
      throwsA(
        isA<ServerFailure>().having(
          (f) => f.message,
          'en',
          'Invalid phone/email or password',
        ),
      ),
    );
    await c.read(localeProvider.notifier).setLocale('bn');
    await expectLater(
      attempt(),
      throwsA(
        isA<ServerFailure>().having(
          (f) => f.message,
          'bn',
          'ফোন/ইমেইল অথবা পাসওয়ার্ড ভুল',
        ),
      ),
    );
  }, skip: !live);

  test('login, authenticated paginated list, logout', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);

    final products = await api.getPage(
      '/products',
      limit: 2,
      item: (j) => j['name'] as String,
    );
    expect(products.limit, 2);
    expect(products.items, isNotEmpty);

    final validation = api.post(
      '/customers',
      body: {'name': '', 'phone': '1'},
      parse: (d) => d,
    );
    await expectLater(
      validation,
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.fieldErrors.keys,
          'fields',
          containsAll(['name', 'phone']),
        ),
      ),
    );

    await api.post('/auth/logout', parse: (d) => d);
    await expectLater(
      api.get('/auth/me', parse: (d) => d),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(c.read(sessionExpiredProvider), 1);
  }, skip: !live);
}
