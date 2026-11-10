import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';

void main() {
  test('the status bar is black with light icons in every theme', () {
    expect(kStatusBarStyle.statusBarColor, Colors.black);
    expect(kStatusBarStyle.statusBarIconBrightness, Brightness.light);
    for (final accent in AccentColor.values) {
      for (final b in Brightness.values) {
        expect(
          AppTheme.build(accent, b).appBarTheme.systemOverlayStyle,
          kStatusBarStyle,
          reason: '$accent $b',
        );
      }
    }
  });
}
