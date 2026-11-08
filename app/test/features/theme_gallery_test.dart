import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/theme/theme_controller.dart';
import 'package:flyash/features/dev/presentation/pages/theme_gallery_page.dart';

import '../helpers.dart';

/// Hosts the gallery with the real theme so tapping changes it.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(themeControllerProvider);
    return MaterialApp(
      theme: AppTheme.build(s.accent, Brightness.light),
      darkTheme: AppTheme.build(s.accent, Brightness.dark),
      themeMode: s.mode,
      home: const ThemeGalleryPage(),
    );
  }
}

void main() {
  // Phone, tablet, desktop (08-Flutter-Plan definition of done)
  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final mode in ['light', 'dark']) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}px ($mode)',
        (tester) async {
          setScreenSize(tester, size);
          await tester.pumpWidget(
            await testApp(const _Host(), prefs: {'theme.mode': mode}),
          );
          await tester.pumpAndSettle();

          expect(find.text('Theme gallery'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('XL font size on a small phone does not overflow', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      await testApp(const _Host(), prefs: {'theme.font_scale': 1.3}),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an accent swatch changes the theme', (tester) async {
    setScreenSize(tester, const Size(1440, 900));
    await tester.pumpWidget(await testApp(const _Host()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(AccentColor.violet.label));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ThemeGalleryPage));
    final container = ProviderScope.containerOf(context);
    expect(container.read(themeControllerProvider).accent, AccentColor.violet);
    expect(
      Theme.of(context).colorScheme.primary,
      AppColors.accent(AccentColor.violet, Brightness.light).primary,
    );
  });
}
