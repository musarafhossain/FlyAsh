import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/theme_controller.dart';

import '../helpers.dart';

Future<void> openHome(WidgetTester tester, Size size) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'theme.mode': 'light'},
      token: 'oat_test',
      api: signedInRoutes(),
    ),
  );
  await tester.pumpAndSettle();
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    testWidgets('app bar order at ${size.width.toInt()} px: '
        'appearance, language, avatar', (tester) async {
      await openHome(tester, size);
      final appearance = tester.getCenter(find.byTooltip('Appearance')).dx;
      final language = tester.getCenter(find.byTooltip('Language')).dx;
      final avatar = tester.getCenter(find.byTooltip('Account')).dx;
      expect(appearance, lessThan(language));
      expect(language, lessThan(avatar));
      expect(avatar, greaterThan(size.width - 80), reason: 'at the right');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('avatar menu: name, Profile, Change password, Log out', (
    tester,
  ) async {
    await openHome(tester, const Size(1440, 900));
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('owner@test.com'), findsOneWidget);

    await tester.tap(find.widgetWithText(MenuItemButton, 'My profile'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/profile');

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/profile/password');
  });

  testWidgets('avatar menu: Log out asks first', (tester) async {
    await openHome(tester, const Size(360, 800));
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/login');
  });

  testWidgets('appearance popover changes mode and color instantly', (
    tester,
  ) async {
    await openHome(tester, const Size(360, 800));
    await tester.tap(find.byTooltip('Appearance'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(testContainer.read(themeControllerProvider).mode, ThemeMode.dark);

    await tester.tap(find.bySemanticsLabel('Emerald'));
    await tester.pumpAndSettle();
    expect(
      testContainer.read(themeControllerProvider).accent,
      AccentColor.emerald,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('More appearance settings'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/settings/appearance');
  });

  testWidgets('language button switches to Bengali', (tester) async {
    await openHome(tester, const Size(1440, 900));
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা').last);
    await tester.pumpAndSettle();
    expect(testContainer.read(localeProvider), 'bn');
    expect(find.byTooltip('চেহারা'), findsOneWidget);
  });

  for (final size in const [Size(360, 800), Size(1440, 900)]) {
    testWidgets('language popover: title, two cards, the chosen one ticked; '
        'picking closes it (${size.width.toInt()} px)', (tester) async {
      await openHome(tester, size);
      final button = tester.getRect(find.byTooltip('Language'));
      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      expect(find.text('App text and server messages'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
      final card = tester.getRect(
        find
            .ancestor(of: find.text('English'), matching: find.byType(Material))
            .first,
      );
      expect(size.width - card.right, greaterThanOrEqualTo(8), reason: 'gap');
      expect(card.top, greaterThan(button.bottom - 1), reason: 'below');

      await tester.tap(find.text('বাংলা').last);
      await tester.pumpAndSettle();
      expect(testContainer.read(localeProvider), 'bn');
      expect(
        find.text('অ্যাপের লেখা আর সার্ভারের বার্তা'),
        findsNothing,
        reason: 'closed',
      );
    });
  }

  // Popovers line up with their button and never touch the screen edge.
  for (final size in const [Size(360, 800), Size(1440, 900)]) {
    for (final (tooltip, item) in [
      ('Appearance', 'More appearance settings'),
      ('Account', 'My profile'),
    ]) {
      testWidgets('$tooltip popover keeps a gap on the right '
          '(${size.width.toInt()} px)', (tester) async {
        await openHome(tester, size);
        final button = tester.getRect(find.byTooltip(tooltip));
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        final menu = tester.getRect(find.widgetWithText(MenuItemButton, item));
        expect(size.width - menu.right, greaterThanOrEqualTo(8));
        // Right-aligned with its button when there is room on the left;
        // otherwise kept inside the screen from the left edge.
        if (button.right >= menu.width) {
          expect(menu.right, closeTo(button.right, 5), reason: 'aligned');
        } else {
          expect(menu.left, greaterThanOrEqualTo(0));
        }
      });
    }
  }

  testWidgets('account button shows a person icon, not initials', (
    tester,
  ) async {
    await openHome(tester, const Size(1440, 900));
    final button = find.byTooltip('Account');
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.person)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: button, matching: find.text('TO')),
      findsNothing,
    );
  });
}
