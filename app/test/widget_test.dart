import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';

void main() {
  testWidgets('app starts and shows the logo and name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlyAshApp()));

    expect(find.text('FlyAsh'), findsOneWidget);
    expect(find.bySemanticsLabel('FlyAsh logo'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
