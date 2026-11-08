import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flyash/core/config/preferences.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/theme/app_tokens.dart';
import 'package:flyash/core/theme/theme_controller.dart';

import '../helpers.dart';

void main() {
  group('10 theme combinations (5 accents × light/dark)', () {
    for (final accent in AccentColor.values) {
      for (final brightness in Brightness.values) {
        test('${accent.name} ${brightness.name}: builds and meets WCAG AA', () {
          final theme = AppTheme.build(accent, brightness);
          final t = theme.extension<AppTokens>()!;

          expect(theme.brightness, brightness);
          expect(theme.colorScheme.primary, t.primary);

          // Text on surfaces
          expect(contrast(t.textPrimary, t.surface), greaterThanOrEqualTo(4.5));
          expect(
            contrast(t.textSecondary, t.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(t.textTertiary, t.surface),
            greaterThanOrEqualTo(4.5),
          );
          // Accent
          expect(contrast(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5));
          expect(contrast(t.primary, t.surface), greaterThanOrEqualTo(4.5));
          expect(
            contrast(t.onPrimaryContainer, t.primaryContainer),
            greaterThanOrEqualTo(4.5),
          );
          // Status pills
          for (final (fg, bg) in [
            (t.success, t.successBg),
            (t.warning, t.warningBg),
            (t.error, t.errorBg),
            (t.info, t.infoBg),
          ]) {
            expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
          }
        });
      }
    }
  });

  group('ThemeController', () {
    Future<ProviderContainer> container(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('defaults: system mode, Royal Blue, font scale 1.0', () async {
      final c = await container({});
      expect(c.read(themeControllerProvider), const ThemeSettings());
    });

    test('saves to the device and restores on the next start', () async {
      final c = await container({});
      final controller = c.read(themeControllerProvider.notifier);
      await controller.setMode(ThemeMode.dark);
      await controller.setAccent(AccentColor.emerald);
      await controller.setFontScale(1.15);

      final prefs = c.read(sharedPreferencesProvider);
      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);

      expect(
        restarted.read(themeControllerProvider),
        const ThemeSettings(
          mode: ThemeMode.dark,
          accent: AccentColor.emerald,
          fontScale: 1.15,
        ),
      );
    });

    test('applies values from the account (API names)', () async {
      final c = await container({});
      await c
          .read(themeControllerProvider.notifier)
          .applyFromAccount(themeMode: 'light', accentColor: 'brick');
      final s = c.read(themeControllerProvider);
      expect(s.mode, ThemeMode.light);
      expect(s.accent, AccentColor.brick);
      expect(s.modeName, 'light');
    });

    test('unknown stored values fall back to defaults', () async {
      final c = await container({
        'theme.mode': 'purple',
        'theme.accent': 'pink',
        'theme.font_scale': 3.0,
      });
      expect(c.read(themeControllerProvider), const ThemeSettings());
    });
  });
}
