import 'package:flutter/material.dart';

/// Type scale (04-UI-UX §6). Inter for Latin text; Bengali characters fall
/// back to Hind Siliguri automatically. Numbers use tabular figures so
/// amounts line up in columns.
abstract final class AppTypography {
  static const String latin = 'Inter';
  static const String bengali = 'HindSiliguri';
  static const List<String> fallback = [bengali];

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle _style(double size, FontWeight weight, double height) =>
      TextStyle(
        fontFamily: latin,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: weight,
        height: height / size,
        letterSpacing: 0,
      );

  // Token → Material slot it fills (used in textTheme below)

  /// displaySmall: hero numbers
  static final display = _style(32, FontWeight.w700, 40);

  /// headlineSmall
  static final h1 = _style(24, FontWeight.w700, 32);

  /// titleLarge: screen titles
  static final h2 = _style(20, FontWeight.w600, 28);

  /// titleMedium: section headers
  static final h3 = _style(17, FontWeight.w600, 24);

  /// titleSmall: list item titles
  static final title = _style(15, FontWeight.w600, 22);

  /// bodyMedium
  static final body = _style(14, FontWeight.w400, 20);

  /// Amounts in line items
  static final bodyStrong = _style(14, FontWeight.w600, 20);

  /// labelLarge: buttons, tabs
  static final label = _style(13, FontWeight.w500, 18);

  /// bodySmall: captions, dates
  static final caption = _style(12, FontWeight.w400, 16);

  /// labelSmall: status pills, nav labels
  static final micro = _style(11, FontWeight.w600, 14);

  /// Material text theme built from the scale, in the given text color.
  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: display.copyWith(
        fontSize: 40,
        height: 48 / 40,
        color: primary,
      ),
      displayMedium: display.copyWith(
        fontSize: 36,
        height: 44 / 36,
        color: primary,
      ),
      displaySmall: display.copyWith(color: primary),
      headlineLarge: h1.copyWith(fontSize: 28, height: 36 / 28, color: primary),
      headlineMedium: h1.copyWith(
        fontSize: 26,
        height: 34 / 26,
        color: primary,
      ),
      headlineSmall: h1.copyWith(color: primary),
      titleLarge: h2.copyWith(color: primary),
      titleMedium: h3.copyWith(color: primary),
      titleSmall: title.copyWith(color: primary),
      bodyLarge: body.copyWith(fontSize: 16, height: 24 / 16, color: primary),
      bodyMedium: body.copyWith(color: primary),
      bodySmall: caption.copyWith(color: secondary),
      labelLarge: label.copyWith(color: primary),
      labelMedium: label.copyWith(fontSize: 12, color: primary),
      labelSmall: micro.copyWith(color: secondary),
    );
  }
}
