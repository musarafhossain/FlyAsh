import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/features/customers/presentation/pages/customers_list_page.dart';
import 'package:flyash/features/expenses/presentation/pages/expenses_list_page.dart';
import 'package:flyash/features/labours/presentation/pages/labours_page.dart';
import 'package:flyash/features/products/presentation/pages/products_list_page.dart';
import 'package:flyash/features/sales/presentation/pages/sales_list_page.dart';
import 'package:flyash/features/settings/presentation/pages/settings_page.dart';
import 'package:flyash/features/users/presentation/pages/users_list_page.dart';

import '../helpers.dart';
import 'expenses_test.dart' show FakeExpenses;
import 'labours_test.dart' show FakeLabours;
import 'products_test.dart' show sampleProducts;
import 'sale_form_test.dart' show FakeSalesBackend;
import 'users_test.dart' show sampleUsers;

/// Every section, list → detail → back (2026-11-16): the page underneath
/// is never faded (so no white flash through it), and on the bottom-bar
/// sections the list's title does not jump over the closing page.
const cases = [
  ('/sales', '/sales/104', SalesListPage, true),
  ('/expenses', '/expenses/55/edit', ExpensesListPage, true),
  ('/customers', '/customers/1', CustomersListPage, false),
  ('/labours', '/labours/9', LaboursPage, false),
  ('/products', '/products/1', ProductsListPage, false),
  ('/users', '/users/6', UsersListPage, false),
  ('/settings', '/settings/about', SettingsPage, false),
];

Future<void> openApp(WidgetTester tester) async {
  setScreenSize(tester, const Size(400, 900));
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-09'},
      token: 'oat_saved',
      api: signedInRoutes({
        ...sampleProducts().routes,
        ...sampleUsers().routes,
        ...FakeLabours().routes,
        ...FakeExpenses().routes,
        ...FakeSalesBackend().routes,
      }),
    ),
  );
  await tester.pumpAndSettle();
}

/// The opacity the list page is drawn with (every FadeTransition above it).
double listOpacity(WidgetTester tester, Type page) {
  var opacity = 1.0;
  for (final f in tester.widgetList<FadeTransition>(
    find.ancestor(of: find.byType(page), matching: find.byType(FadeTransition)),
  )) {
    opacity *= f.opacity.value;
  }
  return opacity;
}

/// The opacity of the pager's titles layer (bottom-bar sections).
double titlesOpacity(WidgetTester tester) {
  final o = find.byWidgetPredicate(
    (w) => w is AnimatedOpacity && w.duration.inMilliseconds == 210,
  );
  if (o.evaluate().isEmpty) return 1;
  // AnimatedOpacity draws through a FadeTransition below it.
  return tester
      .widget<FadeTransition>(
        find
            .descendant(of: o.first, matching: find.byType(FadeTransition))
            .first,
      )
      .opacity
      .value;
}

void main() {
  for (final (list, detail, page, pager) in cases) {
    testWidgets('$list → $detail → back: the list is never faded', (
      tester,
    ) async {
      await openApp(tester);
      final router = testContainer.read(routerProvider);
      router.go(list);
      await tester.pumpAndSettle();
      unawaited(router.push(detail));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, detail);

      router.pop();
      // Through the whole back animation.
      final seen = <double>[];
      final titles = <double>[];
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        seen.add(listOpacity(tester, page));
        if (pager) titles.add(titlesOpacity(tester));
      }
      expect(seen, everyElement(1.0), reason: 'the list stays fully drawn');
      if (pager) {
        expect(titles.first, lessThan(1), reason: 'titles fade in, no jump');
        expect(titles.last, closeTo(1, 0.01));
      }
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, list);
      expect(tester.takeException(), isNull);
    });
  }
}
