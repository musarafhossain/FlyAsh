import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';

import 'helpers.dart';

void main() {
  testWidgets('app starts and shows the logo and name', (tester) async {
    await tester.pumpWidget(await testApp(const FlyAshApp()));
    await tester.pumpAndSettle();

    expect(find.text('FlyAsh'), findsOneWidget);
    expect(find.bySemanticsLabel('FlyAsh logo'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('uses the saved dark theme from the first frame', (tester) async {
    await tester.pumpWidget(
      await testApp(const FlyAshApp(), prefs: {'theme.mode': 'dark'}),
    );

    final context = tester.element(find.text('FlyAsh'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
