import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/core/widgets/list_items.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Map<String, Object?> user(
  int id,
  String name,
  String phone, {
  String? email,
  bool active = true,
  String? lastLogin,
}) => {
  'id': id,
  'name': name,
  'phone': phone,
  'email': email,
  'locale': 'en',
  'theme_mode': 'system',
  'accent_color': 'blue',
  'is_active': active,
  'last_login_at': lastLogin,
};

/// A small in-memory Users API (07-API §6).
class FakeUsers {
  FakeUsers(this.users);

  final List<Map<String, Object?>> users;
  final requests = <RequestOptions>[];

  Reply _page(RequestOptions o) {
    final search = (o.queryParameters['search'] as String? ?? '').toLowerCase();
    final items = [
      for (final u in users)
        if (search.isEmpty ||
            (u['name'] as String).toLowerCase().contains(search) ||
            (u['phone'] as String).contains(search))
          u,
    ];
    return (
      200,
      envelope(200, 'Users fetched successfully', {
        'items': items,
        'page': 1,
        'limit': 20,
        'total': items.length,
        'last_page': 1,
      }),
      {},
    );
  }

  Reply _validation(String field, String message) => (
    422,
    envelope(422, 'Validation failed', {
      'errors': [
        {'field': field, 'message': message},
      ],
    }),
    {},
  );

  FakeRoutes get routes => {
    'GET /users': _page,
    'POST /users': (o) {
      final b = body(o);
      if (b['phone'] == '9876543210') {
        return _validation('phone', 'This phone is already taken');
      }
      final created = user(
        10,
        b['name']! as String,
        b['phone']! as String,
        email: b['email'] as String?,
      );
      users.add(created);
      return (201, envelope(201, 'User created successfully', created), {});
    },
    for (final u in users) ...{
      'GET /users/${u['id']}': (_) =>
          (200, envelope(200, 'User fetched successfully', u), {}),
      'PUT /users/${u['id']}': (o) {
        u.addAll(body(o));
        return (200, envelope(200, 'User updated successfully', u), {});
      },
      'PATCH /users/${u['id']}/status': (o) {
        final active = body(o)['is_active']! as bool;
        u['is_active'] = active;
        return (
          200,
          envelope(200, active ? 'User activated' : 'User deactivated', u),
          {},
        );
      },
      'PUT /users/${u['id']}/password': (o) => (
        200,
        envelope(
          200,
          'Password reset. The user was logged out of all devices',
          null,
        ),
        {},
      ),
    },
  };
}

FakeUsers sampleUsers() => FakeUsers([
  user(
    6,
    'Munshi Kalam',
    '9000074686',
    email: 'munshi@test.com',
    lastLogin: '2026-11-08T14:55:46.000Z',
  ),
  user(2, 'Rafiq Sheikh', '9000069860', active: false),
]);

Future<FakeUsers> openUsers(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  FakeUsers? fake,
  String location = '/users',
}) async {
  final api = fake ?? sampleUsers();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      token: 'oat_saved',
      api: signedInRoutes(api.routes),
      requests: api.requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return api;
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  testWidgets('phone: users are cards with status and last login', (
    tester,
  ) async {
    await openUsers(tester);
    expect(find.byType(EntityListTile), findsNWidgets(2));
    expect(find.text('Munshi Kalam'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Last login: Never'), findsOneWidget);
    expect(find.text('Showing 2 of 2'), findsOneWidget);
    expect(find.byType(DataTableCard), findsNothing);
  });

  testWidgets('desktop: users are a table', (tester) async {
    await openUsers(tester, size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('Last login'), findsOneWidget); // column header
    expect(find.text('munshi@test.com'), findsOneWidget);
  });

  testWidgets('empty list explains and offers Add user', (tester) async {
    await openUsers(tester, fake: FakeUsers([]));
    expect(find.text('Only you so far'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add user'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/users/new');
  });

  testWidgets('search asks the server with ?search=', (tester) async {
    final api = await openUsers(tester);
    await tester.enterText(find.byType(TextField).first, 'rafiq');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['search'], 'rafiq');
    expect(find.byType(EntityListTile), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'nobody');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('add user: checks the form, shows server errors, then saves', (
    tester,
  ) async {
    final api = await openUsers(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/users/new');

    final fields = find.byType(TextFormField);
    // Client-side rules first
    await tester.enterText(fields.at(0), 'Kartik');
    await tester.enterText(fields.at(1), '12345');
    await tester.enterText(fields.at(3), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Add user'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a 10-digit mobile number starting with 6–9'),
      findsOneWidget,
    );
    expect(find.text('At least 6 characters'), findsWidgets);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);

    // Server says the phone is taken
    await tester.enterText(fields.at(1), '9876543210');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Add user'));
    await tester.pumpAndSettle();
    expect(find.text('This phone is already taken'), findsOneWidget);

    // Saved → back to the list, which now has the new user
    await tester.enterText(fields.at(1), '9123456780');
    await tester.tap(find.widgetWithText(FilledButton, 'Add user'));
    await tester.pumpAndSettle();
    final post = api.requests.lastWhere((r) => r.method == 'POST');
    expect(body(post), {
      'name': 'Kartik',
      'phone': '9123456780',
      'email': null,
      'password': 'secret123',
    });
    expect(currentPath(), '/users');
    expect(find.text('User added'), findsOneWidget);
    expect(find.text('Kartik'), findsOneWidget);
  });

  testWidgets('detail → edit saves and shows the new name', (tester) async {
    await openUsers(tester);
    await tester.tap(find.text('Munshi Kalam'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/users/6');
    expect(find.text('9000074686'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/users/6/edit');
    expect(find.byType(TextFormField), findsNWidgets(3)); // no password

    await tester.enterText(find.byType(TextFormField).first, 'Munshi K.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/users/6');
    expect(find.text('Munshi K.'), findsWidgets);
  });

  testWidgets('deactivate asks first, then shows Inactive', (tester) async {
    final api = await openUsers(tester, location: '/users/6');
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Munshi Kalam?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();

    final patch = api.requests.lastWhere((r) => r.method == 'PATCH');
    expect(body(patch), {'is_active': false});
    expect(find.text('User deactivated'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
  });

  testWidgets('reset password for another user', (tester) async {
    final api = await openUsers(tester, location: '/users/6');
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    final dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(dialogFields.at(0), 'newpass1');
    await tester.enterText(dialogFields.at(1), 'newpass2');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(dialogFields.at(1), 'newpass1');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();
    final put = api.requests.lastWhere((r) => r.path == '/users/6/password');
    expect(body(put), {
      'password': 'newpass1',
      'password_confirmation': 'newpass1',
    });
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('Password reset. The user was logged out of all devices'),
      findsOneWidget,
    );
  });

  testWidgets('an unknown user id shows an error with Retry', (tester) async {
    await openUsers(tester, location: '/users/99');
    expect(find.text('Route not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
