import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/theme/app_theme.dart';

import '../helpers.dart';

/// The visible snackbar card (the SnackBar widget itself spans the screen).
Finder visibleSnackBar() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

/// Shows a snackbar on the Login screen and returns its visible width.
Future<double> snackBarWidth(WidgetTester tester, Size screen) async {
  setScreenSize(tester, screen);
  await tester.pumpWidget(await testApp(const FlyAshApp()));
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(Scaffold).first);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Password changed. Please log in')),
  );
  await tester.pumpAndSettle();
  return tester.getSize(visibleSnackBar()).width;
}

void main() {
  testWidgets('desktop: snackbar is narrow and centered, not full width', (
    tester,
  ) async {
    final width = await snackBarWidth(tester, const Size(1440, 900));
    expect(width, AppTheme.snackBarMaxWidth);
    final rect = tester.getRect(visibleSnackBar());
    expect(rect.center.dx, closeTo(720, 1), reason: 'centered');
  });

  testWidgets('tablet: also narrow', (tester) async {
    expect(
      await snackBarWidth(tester, const Size(800, 1000)),
      AppTheme.snackBarMaxWidth,
    );
  });

  testWidgets('phone: spans the screen with side margins', (tester) async {
    final width = await snackBarWidth(tester, const Size(360, 800));
    expect(width, lessThan(360));
    expect(width, greaterThan(300));
  });
}
