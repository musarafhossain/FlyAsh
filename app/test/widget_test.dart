import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';

import 'helpers.dart';

void main() {
  testWidgets('without a saved session the app opens Login', (tester) async {
    await tester.pumpWidget(await testApp(const FlyAshApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.bySemanticsLabel('FlyAsh logo'), findsOneWidget);
  });

  testWidgets('uses the saved dark theme from the first frame', (tester) async {
    await tester.pumpWidget(
      await testApp(const FlyAshApp(), prefs: {'theme.mode': 'dark'}),
    );

    final context = tester.element(find.bySemanticsLabel('FlyAsh logo'));
    expect(Theme.of(context).brightness, Brightness.dark);
    await tester.pumpAndSettle();
  });
}
