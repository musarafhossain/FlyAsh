import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/widgets/app_refresh_indicator.dart';

void main() {
  testWidgets('the pull circle has a clear shadow; the page keeps the theme', (
    tester,
  ) async {
    final theme = AppTheme.build(AccentColor.values.first, Brightness.light);
    late ThemeData pageTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AppRefreshIndicator(
            onRefresh: () async {},
            child: Builder(
              builder: (context) {
                pageTheme = Theme.of(context);
                return ListView(children: const [Text('row')]);
              },
            ),
          ),
        ),
      ),
    );
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.elevation, AppRefreshIndicator.elevation);
    expect(indicator.elevation, greaterThan(2), reason: 'above the default');
    expect(pageTheme.colorScheme.shadow, theme.colorScheme.shadow);

    // Pull: the circle's Material uses the darker shadow.
    await tester.fling(find.text('row'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final circle = find.descendant(
      of: find.byType(RefreshProgressIndicator),
      matching: find.byType(Material),
    );
    expect(circle, findsWidgets);
    final context = tester.element(circle.first);
    expect(Theme.of(context).colorScheme.shadow, AppRefreshIndicator.shadow);
    await tester.pumpAndSettle();
  });

  test('every pull to refresh uses AppRefreshIndicator', () {
    final raw = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('app_refresh_indicator.dart')) continue;
      final text = f.readAsStringSync();
      if (RegExp(r'(?<!App)RefreshIndicator\(').hasMatch(text)) raw.add(f.path);
    }
    expect(raw, isEmpty);
  });
}
