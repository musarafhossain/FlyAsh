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
import 'package:flyash/core/utils/dates.dart';
import 'package:flyash/features/auth/data/auth_repository_impl.dart';
import 'package:flyash/features/customers/data/customers_repository_impl.dart';
import 'package:flyash/features/customers/domain/customer.dart';
import 'package:flyash/features/attendance/data/attendance_repository_impl.dart';
import 'package:flyash/features/labours/data/labours_repository_impl.dart';
import 'package:flyash/features/labours/domain/labour.dart';
import 'package:flyash/features/products/data/products_repository_impl.dart';
import 'package:flyash/features/products/domain/product.dart';
import 'package:flyash/features/sales/data/sales_repository_impl.dart';
import 'package:flyash/features/sales/domain/sale.dart';
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

  // F9: customer life cycle; the test customer is deleted at the end.
  test('F9: customers create, duplicate phone, edit, sales, delete', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final repo = c.read(customersRepositoryProvider);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final phone = '9${(stamp % 1000000000).toString().padLeft(9, '0')}';

    final created = await repo.create(
      CustomerInput(name: 'Live test customer $stamp', phone: phone),
    );
    expect(created.totalDue, '0.00');
    expect(created.hasDue, isFalse);

    await expectLater(
      repo.create(CustomerInput(name: 'Duplicate', phone: phone)),
      throwsA(
        isA<ValidationFailure>()
            .having((f) => f['phone'], 'phone', isNotNull)
            .having(
              (f) => f.data?['existing_customer_id'],
              'existing id',
              created.id,
            ),
      ),
    );

    final found = await repo.list(search: phone);
    expect(found.items.single.id, created.id);

    final edited = await repo.update(
      created.id,
      CustomerInput(name: created.name, phone: phone, address: 'Habra'),
    );
    expect(edited.address, 'Habra');
    expect((await repo.sales(created.id)).items, isEmpty);

    final (inactive, _) = await repo.setActive(created.id, false);
    expect(inactive.isActive, isFalse);

    expect(await repo.delete(created.id), isNotEmpty);
    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);

  // F10: read-only checks of the sales list, filters, detail and upcoming.
  test('F10: sales list, filters, detail, upcoming deliveries', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final repo = c.read(salesRepositoryProvider);

    final all = await repo.list();
    expect(all.items, isNotEmpty, reason: 'the dev database has sales');
    final first = all.items.first;
    expect(first.invoiceNo, matches(RegExp(r'^[A-Z]')));
    expect(first.customerName, isNotNull);

    final bookings = await repo.list(filter: const SaleFilter(type: 'booking'));
    expect(bookings.items.every((s) => s.type == 'booking'), isTrue);

    final partial = await repo.list(
      filter: const SaleFilter(status: 'partial'),
    );
    expect(
      partial.items.every(
        (s) => s.status == 'delivered' && s.paymentStatus == 'partial',
      ),
      isTrue,
    );

    final today = c.read(businessDateProvider);
    final month = DateRange.preset(DatePreset.thisMonth, today);
    final inMonth = await repo.list(filter: SaleFilter(range: month));
    expect(
      inMonth.items.every(
        (s) =>
            s.saleDate.compareTo(month.from!) >= 0 &&
            s.saleDate.compareTo(month.to!) <= 0,
      ),
      isTrue,
    );

    final bySearch = await repo.list(
      filter: SaleFilter(search: first.invoiceNo),
    );
    expect(bySearch.items.map((s) => s.id), contains(first.id));

    final sale = await repo.get(first.id);
    expect(sale.summary.invoiceNo, first.invoiceNo);
    expect(sale.items, isNotEmpty);

    final upcoming = await repo.upcoming();
    expect(upcoming.items.every((s) => s.status == 'booked'), isTrue);

    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);

  // F11: creates real sales with the live user. The cleanup (sales, the
  // test product and customer) is done afterwards in the database, because
  // the API keeps records that have sales.
  test('F11: create, pay, edit, deliver, cancel, delete', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final sales = c.read(salesRepositoryProvider);
    final today = c.read(businessDateProvider);
    final stamp = DateTime.now().millisecondsSinceEpoch;

    final product = await c
        .read(productsRepositoryProvider)
        .create(
          ProductInput(
            name: 'Live sale brick $stamp',
            unit: ProductUnit.piece,
            defaultCost: '4.2',
            defaultPrice: '6.5',
          ),
        );
    final phone = '8${(stamp % 1000000000).toString().padLeft(9, '0')}';
    SaleItemInput item(String qty) => SaleItemInput(
      productId: product.id,
      quantity: qty,
      unitCost: '4.2',
      unitPrice: '6.5',
    );

    // Instant sale with a new customer and money received now
    final (sale, msg) = await sales.create(
      SaleInput(
        type: 'instant',
        newCustomer: NewCustomerInput(
          name: 'Live sale customer $stamp',
          phone: phone,
        ),
        saleDate: today,
        items: [item('1000')],
        transportCharge: '500',
        discount: '100',
        payment: const PaymentInput(amount: '2000', method: 'upi'),
      ),
    );
    expect(msg, isNotEmpty);
    expect(sale.summary.total, '6900.00'); // 6500 + 500 − 100
    expect(sale.profit, '2700.00'); // 6900 − 4200
    expect(sale.summary.dueAmount, '4900.00');
    expect(sale.summary.status, 'delivered');
    final customerId = sale.summary.customerId!;

    // Payment above the due → 400
    await expectLater(
      sales.addPayment(sale.id, const PaymentInput(amount: '99999')),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );
    final (paid, _) = await sales.addPayment(
      sale.id,
      PaymentInput(amount: '4900', paymentDate: today),
    );
    expect(paid.summary.paymentStatus, 'paid');

    // Edit below what was paid → 400; a bigger edit works
    final editLow = SaleInput(
      type: 'instant',
      customerId: customerId,
      saleDate: today,
      items: [item('10')],
    );
    await expectLater(
      sales.update(sale.id, editLow),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );
    final (edited, _) = await sales.update(
      sale.id,
      SaleInput(
        type: 'instant',
        customerId: customerId,
        saleDate: today,
        items: [item('1200')],
      ),
    );
    expect(edited.summary.total, '7800.00');
    expect(edited.summary.dueAmount, '900.00');

    final lastPayment = edited.payments.last;
    final (afterDelete, _) = await sales.deletePayment(sale.id, lastPayment.id);
    expect(afterDelete.payments.length, edited.payments.length - 1);

    // Booking: deliver
    final (booking, _) = await sales.create(
      SaleInput(
        type: 'booking',
        customerId: customerId,
        saleDate: today,
        deliveryDate: today,
        deliveryAddress: 'Live test road',
        items: [item('500')],
      ),
    );
    expect(booking.summary.status, 'booked');
    final upcoming = await sales.upcoming();
    expect(upcoming.items.map((s) => s.id), contains(booking.id));
    final (delivered, _) = await sales.deliver(
      booking.id,
      deliveredDate: today,
    );
    expect(delivered.summary.status, 'delivered');

    // Booking: cancel is refused with a payment, works without
    final (booking2, _) = await sales.create(
      SaleInput(
        type: 'booking',
        customerId: customerId,
        saleDate: today,
        deliveryDate: today,
        items: [item('100')],
        payment: const PaymentInput(amount: '100'),
      ),
    );
    await expectLater(
      sales.cancel(booking2.id),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );
    await sales.deletePayment(booking2.id, booking2.payments.single.id);
    final (cancelled, _) = await sales.cancel(booking2.id);
    expect(cancelled.summary.status, 'cancelled');

    // Delete (soft) removes it from the list
    expect(await sales.delete(booking2.id), isNotEmpty);
    await expectLater(
      sales.get(booking2.id),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 404)),
    );

    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);

  // F12: a test labour; attendance is saved and cleared only for them.
  // The labour row is removed afterwards in the database.
  test('F12: labours and attendance', () async {
    final api = c.read(apiClientProvider);
    final res = await api.post(
      '/auth/login',
      body: {'login': login, 'password': password},
      parse: (d) => d as Json,
    );
    await c.read(tokenStoreProvider).save(res.data['token'] as String);
    final labours = c.read(laboursRepositoryProvider);
    final attendance = c.read(attendanceRepositoryProvider);
    final today = c.read(businessDateProvider);
    final stamp = DateTime.now().millisecondsSinceEpoch;

    final created = await labours.create(
      LabourInput(
        name: 'Live test labour $stamp',
        wageType: 'daily',
        wageAmount: '450',
        joiningDate: Ymd.addDays(today, -5),
      ),
    );
    expect(created.wageAmount, '450.00');
    expect(created.todayStatus, isNull);

    final edited = await labours.update(
      created.id,
      LabourInput(
        name: created.name,
        wageType: 'monthly',
        wageAmount: '15000',
        joiningDate: created.joiningDate,
      ),
    );
    expect(edited.isMonthly, isTrue);

    final day = await attendance.day(today);
    expect(day.entries.map((e) => e.labourId), contains(created.id));

    final (saved, msg) = await attendance.save(today, {created.id: 'present'});
    expect(msg, isNotEmpty);
    expect(
      saved.entries.firstWhere((e) => e.labourId == created.id).status,
      'present',
    );
    expect((await labours.get(created.id)).todayStatus, 'present');

    final month = await labours.month(created.id, today.substring(0, 7));
    expect(month.days[today], 'present');
    expect(month.present, 1);

    final (cleared, _) = await attendance.save(today, {created.id: null});
    expect(
      cleared.entries.firstWhere((e) => e.labourId == created.id).status,
      isNull,
    );

    // Before joining → refused
    await expectLater(
      attendance.save(Ymd.addDays(today, -30), {created.id: 'present'}),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );

    await expectLater(
      labours.setActive(created.id, false, leftDate: Ymd.addDays(today, -10)),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 400)),
    );
    final (left, _) = await labours.setActive(
      created.id,
      false,
      leftDate: today,
    );
    expect(left.isActive, isFalse);
    expect(left.leftDate, today);
    final (back, _) = await labours.setActive(created.id, true);
    expect(back.leftDate, isNull);

    await api.post('/auth/logout', parse: (d) => d);
  }, skip: !live);
}
