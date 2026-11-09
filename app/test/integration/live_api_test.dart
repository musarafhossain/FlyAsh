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
import 'package:flyash/features/auth/data/auth_repository_impl.dart';
import 'package:flyash/features/products/data/products_repository_impl.dart';
import 'package:flyash/features/products/domain/product.dart';
import 'package:flyash/features/settings/data/settings_repository_impl.dart';
import 'package:flyash/features/users/data/users_repository_impl.dart';

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

    // Preferences are saved to the account (F5 sync uses this endpoint).
    final prefs = await api.put(
      '/auth/preferences',
      body: {'theme_mode': 'dark', 'accent_color': 'emerald'},
      parse: (d) => d as Json,
    );
    expect(prefs.data['theme_mode'], 'dark');
    expect(prefs.data['accent_color'], 'emerald');
    await api.put(
      '/auth/preferences',
      body: {'theme_mode': 'system', 'accent_color': 'blue'},
      parse: (d) => d,
    );

    await api.post('/auth/logout', parse: (d) => d);
    await expectLater(
      api.get('/auth/me', parse: (d) => d),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(c.read(sessionExpiredProvider), 1);
  }, skip: !live);

  // F7 repositories against the real API. Nothing is changed: saves send
  // the same values back, and the wrong-password call is rejected.
  test('F7: profile, users and factory repositories', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final auth = c.read(authRepositoryProvider);
    final users = c.read(usersRepositoryProvider);
    final settings = c.read(settingsRepositoryProvider);

    final me = await auth.me();
    expect(me.lastLoginAt, isNotNull);
    final same = await auth.updateMe(
      name: me.name,
      phone: me.phone,
      email: me.email,
    );
    expect(same.name, me.name);

    await expectLater(
      auth.changePassword(
        currentPassword: 'definitely-wrong',
        password: 'newpass1',
        confirmation: 'newpass1',
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f['current_password'],
          'field',
          isNotNull,
        ),
      ),
    );

    final page = await users.list();
    expect(page.items.map((u) => u.id), isNot(contains(me.id)));
    if (page.items.isNotEmpty) {
      final other = await users.get(page.items.first.id);
      expect(other.phone, page.items.first.phone);
    }
    await expectLater(
      users.get(me.id),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );

    final factory = await settings.getFactory();
    final (saved, message) = await settings.saveFactory(factory);
    expect(saved.invoicePrefix, factory.invoicePrefix);
    expect(message, isNotEmpty);

    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);

  // F8: the full product life cycle; the test product is deleted at the end.
  test('F8: products create, list, edit, deactivate, delete', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final repo = c.read(productsRepositoryProvider);
    final name = 'Live test brick ${DateTime.now().millisecondsSinceEpoch}';

    final created = await repo.create(
      ProductInput(
        name: name,
        unit: ProductUnit.other,
        unitLabel: 'cft',
        defaultCost: '4.5',
        defaultPrice: '7',
      ),
    );
    expect(created.defaultCost, '4.50');
    expect(created.margin, '2.50');
    expect(created.unitLabel, 'cft');

    await expectLater(
      repo.create(
        ProductInput(
          name: name,
          unit: ProductUnit.piece,
          defaultCost: '1',
          defaultPrice: '2',
        ),
      ),
      throwsA(
        isA<ValidationFailure>().having((f) => f['name'], 'name', isNotNull),
      ),
    );

    final found = await repo.list(search: name);
    expect(found.items.single.id, created.id);

    final edited = await repo.update(
      created.id,
      ProductInput(
        name: name,
        unit: ProductUnit.piece,
        defaultCost: '6',
        defaultPrice: '5.5',
      ),
    );
    expect(edited.margin, '-0.50');
    expect(edited.isLoss, isTrue);

    final (inactive, _) = await repo.setActive(created.id, false);
    expect(inactive.isActive, isFalse);
    final inactiveList = await repo.list(search: name, active: false);
    expect(inactiveList.items.map((p) => p.id), contains(created.id));

    expect(await repo.delete(created.id), isNotEmpty);
    await expectLater(
      repo.get(created.id),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 404)),
    );

    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);
}
