import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/nav_items.dart';

import '../fake_api.dart';
import '../helpers.dart';

/// The address the browser shows for the current screen.
String shownUrl() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

final FakeRoutes forgotRoutes = {
  'POST /auth/forgot-password': (_) => (
    200,
    envelope(200, 'If this email is registered, an OTP has been sent', null),
    {},
  ),
  'POST /auth/verify-otp': (_) =>
      (200, envelope(200, 'OTP verified', {'reset_token': 'signed.token'}), {}),
  'POST /auth/reset-password': (_) =>
      (200, envelope(200, 'Password changed. Please log in', null), {}),
};

void main() {
  testWidgets('splash shows /splash while the session is checked', (
    tester,
  ) async {
    await tester.pumpWidget(
      await testApp(
        const FlyAshApp(),
        token: 'oat_saved',
        api: signedInRoutes(),
      ),
    );
    expect(shownUrl(), '/splash');
    await tester.pumpAndSettle();
    expect(shownUrl(), '/home');
  });

  testWidgets(
    'login → forgot password → OTP → new password → login all have their own URL',
    (tester) async {
      setScreenSize(tester, const Size(800, 1000));
      await tester.pumpWidget(
        await testApp(const FlyAshApp(), api: forgotRoutes),
      );
      await tester.pumpAndSettle();
      expect(shownUrl(), '/login');

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(shownUrl(), '/forgot-password');

      await tester.enterText(find.byType(TextFormField), 'owner@test.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
      await tester.pumpAndSettle();
      expect(shownUrl(), '/forgot-password/verify');

      // Change email → back to the email step URL
      await tester.tap(find.widgetWithText(TextButton, 'Change'));
      await tester.pumpAndSettle();
      expect(shownUrl(), '/forgot-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
      await tester.pumpAndSettle();
      expect(shownUrl(), '/forgot-password/verify');

      await tester.enterText(find.byKey(const Key('otp-input')), '123456');
      await tester.pumpAndSettle();
      expect(shownUrl(), '/forgot-password/reset');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newpass1');
      await tester.enterText(fields.at(1), 'newpass1');
      await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(shownUrl(), '/login');
    },
  );

  testWidgets('every section has its own URL (desktop sidebar)', (
    tester,
  ) async {
    setScreenSize(tester, const Size(1440, 900));
    await tester.pumpWidget(
      await testApp(
        const FlyAshApp(),
        token: 'oat_saved',
        api: signedInRoutes(),
      ),
    );
    await tester.pumpAndSettle();
    expect(shownUrl(), '/home');

    for (final item in kNavItems) {
      await tester.tap(find.text(item.label).first);
      await tester.pumpAndSettle();
      expect(shownUrl(), item.path, reason: item.label);
    }
  });

  testWidgets('every section has its own URL (phone: bottom bar + drawer)', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      await testApp(
        const FlyAshApp(),
        token: 'oat_saved',
        api: signedInRoutes(),
      ),
    );
    await tester.pumpAndSettle();

    for (final item in kNavItems) {
      final bar = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(item.label),
      );
      if (bar.evaluate().isNotEmpty) {
        await tester.tap(bar);
      } else {
        await tester.tap(find.byTooltip('Menu'));
        await tester.pumpAndSettle();
        final entry = find.descendant(
          of: find.byType(Drawer),
          matching: find.text(item.label),
        );
        await tester.ensureVisible(entry);
        await tester.pumpAndSettle();
        await tester.tap(entry);
      }
      await tester.pumpAndSettle();
      expect(shownUrl(), item.path, reason: item.label);
    }
  });

  testWidgets('debug galleries have their own URL', (tester) async {
    setScreenSize(tester, const Size(1440, 900));
    await tester.pumpWidget(
      await testApp(
        const FlyAshApp(),
        token: 'oat_saved',
        api: signedInRoutes(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme gallery'));
    await tester.pumpAndSettle();
    expect(shownUrl(), '/dev/theme');

    testContainer.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(shownUrl(), '/settings');

    await tester.tap(find.text('Widget gallery'));
    await tester.pump(const Duration(seconds: 1));
    expect(shownUrl(), '/dev/widgets');
  });
}
