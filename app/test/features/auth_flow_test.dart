import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/network/api_client.dart';
import 'package:flyash/core/network/session.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/theme_controller.dart';
import 'package:flyash/features/auth/presentation/auth_controller.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Finder appBarTitle(String t) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(t));

/// Fake auth API: password "secret123", OTP "123456".
FakeRoutes authRoutes({Map<String, Object?> user = sampleUser}) => {
  'POST /auth/login': (o) {
    final b = body(o);
    if (b['login'] == 'bad-login') {
      return (
        422,
        envelope(422, 'Validation failed', {
          'errors': [
            {
              'field': 'login',
              'message': 'The phone or email field is required',
            },
          ],
        }),
        {},
      );
    }
    return b['password'] == 'secret123'
        ? (
            200,
            envelope(200, 'Login successful', {
              'token': 'oat_new',
              'user': user,
            }),
            {},
          )
        : (400, envelope(400, 'Invalid phone/email or password', null), {});
  },
  'GET /auth/me': (_) => (200, envelope(200, 'ok', user), {}),
  'POST /auth/logout': (_) =>
      (200, envelope(200, 'Logged out successfully', null), {}),
  'POST /auth/forgot-password': (_) => (
    200,
    envelope(200, 'If this email is registered, an OTP has been sent', null),
    {},
  ),
  'POST /auth/verify-otp': (o) => body(o)['otp'] == '123456'
      ? (
          200,
          envelope(200, 'OTP verified', {'reset_token': 'signed.token'}),
          {},
        )
      : (400, envelope(400, 'Wrong OTP. 4 tries left', {'tries_left': 4}), {}),
  'POST /auth/reset-password': (o) => body(o)['reset_token'] == 'signed.token'
      ? (200, envelope(200, 'Password changed. Please log in', null), {})
      : (
          400,
          envelope(400, 'Reset session expired. Please start again', null),
          {},
        ),
};

Future<void> start(
  WidgetTester tester, {
  String? token,
  FakeRoutes? api,
  List<RequestOptions>? requests,
  Size size = const Size(800, 1000),
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      token: token,
      api: api ?? authRoutes(),
      requests: requests,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester, String login, String password) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Phone or email'),
    login,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  group('login', () {
    testWidgets(
      'success opens Home, saves the token and applies account preferences',
      (tester) async {
        await start(
          tester,
          api: authRoutes(
            user: {...sampleUser, 'locale': 'bn', 'accent_color': 'violet'},
          ),
        );
        await signIn(tester, '9876543210', 'secret123');

        expect(
          appBarTitle('হোম'),
          findsOneWidget,
          reason: 'account language applied',
        );
        expect(testContainer.read(tokenStoreProvider).token, 'oat_new');
        expect(testContainer.read(localeProvider), 'bn');
        expect(
          testContainer.read(themeControllerProvider).accent,
          AccentColor.violet,
        );
        expect(
          testContainer.read(authControllerProvider).user?.name,
          'Test Owner',
        );
      },
    );

    testWidgets('wrong password shows the server message and stays on Login', (
      tester,
    ) async {
      await start(tester);
      await signIn(tester, '9876543210', 'nope');
      expect(find.text('Invalid phone/email or password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('empty fields are checked before calling the API', (
      tester,
    ) async {
      final requests = <RequestOptions>[];
      await start(tester, requests: requests);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required'), findsNWidgets(2));
      expect(requests.where((r) => r.path == '/auth/login'), isEmpty);
    });

    testWidgets('server field errors show under the field', (tester) async {
      await start(tester);
      await signIn(tester, 'bad-login', 'secret123');
      expect(find.text('The phone or email field is required'), findsOneWidget);
    });
  });

  group('startup', () {
    testWidgets('saved token + valid session opens Home', (tester) async {
      await start(tester, token: 'oat_saved');
      expect(appBarTitle('Home'), findsOneWidget);
    });

    testWidgets(
      'saved token rejected by the server (401) opens Login and clears it',
      (tester) async {
        await start(
          tester,
          token: 'oat_revoked',
          api: {
            'GET /auth/me': (_) =>
                (401, envelope(401, 'Unauthorized', null), {}),
          },
        );
        expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
        expect(testContainer.read(tokenStoreProvider).hasToken, isFalse);
      },
    );

    testWidgets('offline at startup keeps the session (Home)', (tester) async {
      await start(
        tester,
        token: 'oat_saved',
        api: {
          'GET /auth/me': (o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
          ),
        },
      );
      expect(appBarTitle('Home'), findsOneWidget);
    });
  });

  testWidgets('a 401 during use ends the session with a notice', (
    tester,
  ) async {
    await start(
      tester,
      token: 'oat_saved',
      api: {
        ...authRoutes(),
        'GET /sales': (_) =>
            (401, envelope(401, 'Your account is deactivated', null), {}),
      },
    );
    expect(appBarTitle('Home'), findsOneWidget);

    // Any authenticated call answering 401 ends the session.
    final call = testContainer
        .read(apiClientProvider)
        .get('/sales', parse: (d) => d)
        .then<Object?>((v) => v, onError: (Object e) => e);
    await tester.pumpAndSettle();
    expect(await call, isNotNull);

    expect(
      find.text('Your session ended. Please sign in again'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('logout from the drawer asks first, then returns to Login', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    await start(
      tester,
      token: 'oat_saved',
      requests: requests,
      size: const Size(360, 800),
    );

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Test Owner · 9876543210'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(requests.map((r) => r.path), contains('/auth/logout'));
    expect(testContainer.read(tokenStoreProvider).hasToken, isFalse);
  });

  group('forgot password (3 screens)', () {
    testWidgets('email → wrong OTP → right OTP → new password → Login', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'owner@test.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('Enter the OTP sent to o•••@test.com'), findsOneWidget);
      expect(find.text('Resend OTP in 60s'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('otp-input')), '000000');
      await tester.pumpAndSettle();
      expect(find.text('Wrong OTP. 4 tries left'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('otp-input')), '123456');
      await tester.pumpAndSettle();
      expect(find.text('Set new password'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newpass1');
      await tester.enterText(fields.at(1), 'different');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.enterText(fields.at(1), 'newpass1');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Password changed. Please log in'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('resend becomes available after 60 seconds', (tester) async {
      await start(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'owner@test.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 61));
      expect(find.widgetWithText(TextButton, 'Resend OTP'), findsOneWidget);
    });
  });

  group('redirect rules', () {
    const signedIn = AuthState(AuthStatus.signedIn);
    test('signed out → login, keeping the requested page', () {
      expect(
        authRedirect(AuthState.signedOut, Uri.parse('/sales')),
        '/login?from=%2Fsales',
      );
      expect(
        authRedirect(AuthState.signedOut, Uri.parse('/forgot-password')),
        isNull,
      );
    });
    test('signed in → back to the requested page, or Home', () {
      expect(
        authRedirect(signedIn, Uri.parse('/login?from=%2Fsales')),
        '/sales',
      );
      expect(authRedirect(signedIn, Uri.parse('/login')), '/home');
      expect(authRedirect(signedIn, Uri.parse('/splash')), '/home');
      expect(authRedirect(signedIn, Uri.parse('/customers')), isNull);
    });
    test('checking → splash; external or public "from" values are ignored', () {
      expect(
        authRedirect(AuthState.checking, Uri.parse('/sales')),
        '/splash?from=%2Fsales',
      );
      expect(
        authRedirect(
          signedIn,
          Uri.parse('/splash?from=https%3A%2F%2Fevil.com'),
        ),
        '/home',
      );
      expect(
        authRedirect(signedIn, Uri.parse('/login?from=%2Flogin')),
        '/home',
      );
    });
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final locale in ['en', 'bn']) {
      testWidgets(
        'login + OTP screens fit at ${size.width.toInt()}px ($locale)',
        (tester) async {
          setScreenSize(tester, size);
          await tester.pumpWidget(
            await testApp(
              const FlyAshApp(),
              api: authRoutes(),
              prefs: {'app.locale': locale, 'theme.font_scale': 1.15},
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'login');

          await tester.tap(find.byType(TextButton).last); // Forgot password?
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextFormField), 'owner@test.com');
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'verify');
        },
      );
    }
  }
}
