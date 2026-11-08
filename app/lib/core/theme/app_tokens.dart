import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic color tokens (04-UI-UX §5). Every widget reads colors from
/// here: `context.tokens.surface`, `context.tokens.success` …
/// Never hard-code a color in a widget.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.overlay,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
    required this.tintRose,
    required this.tintRoseBg,
    required this.tintGreen,
    required this.tintGreenBg,
    required this.tintAmber,
    required this.tintAmberBg,
    required this.tintSky,
    required this.tintSkyBg,
  });

  // Neutrals (§5.1)
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color overlay;

  // Accent (§5.2)
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  // Status (§5.3): foreground + soft background
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;

  // KPI chip tints (§5.4): icon + background
  final Color tintRose;
  final Color tintRoseBg;
  final Color tintGreen;
  final Color tintGreenBg;
  final Color tintAmber;
  final Color tintAmberBg;
  final Color tintSky;
  final Color tintSkyBg;

  /// Builds the tokens for one accent in one mode.
  factory AppTokens.of(AccentColor accent, Brightness brightness) {
    final a = AppColors.accent(accent, brightness);
    if (brightness == Brightness.light) {
      return AppTokens(
        background: const Color(0xFFF5F7FB),
        surface: Colors.white,
        surfaceVariant: const Color(0xFFF1F4F9),
        surfaceElevated: Colors.white,
        border: const Color(0xFFE3E8F0),
        textPrimary: const Color(0xFF0F172A),
        textSecondary: const Color(0xFF475569),
        textTertiary: const Color(0xFF64748B),
        textDisabled: const Color(0xFF94A3B8),
        overlay: const Color(0x730F172A),
        primary: a.primary,
        onPrimary: a.onPrimary,
        primaryContainer: a.primaryContainer,
        onPrimaryContainer: a.onPrimaryContainer,
        success: const Color(0xFF15803D),
        successBg: const Color(0xFFDCFCE7),
        warning: const Color(0xFFB45309),
        warningBg: const Color(0xFFFEF3C7),
        error: const Color(0xFFB91C1C),
        errorBg: const Color(0xFFFEE2E2),
        info: const Color(0xFF0369A1),
        infoBg: const Color(0xFFE0F2FE),
        tintRose: const Color(0xFFBE185D),
        tintRoseBg: const Color(0xFFFCE7F3),
        tintGreen: const Color(0xFF15803D),
        tintGreenBg: const Color(0xFFDCFCE7),
        tintAmber: const Color(0xFFB45309),
        tintAmberBg: const Color(0xFFFEF3C7),
        tintSky: const Color(0xFF0369A1),
        tintSkyBg: const Color(0xFFE0F2FE),
      );
    }
    return AppTokens(
      background: const Color(0xFF0B1120),
      surface: const Color(0xFF131B2E),
      surfaceVariant: const Color(0xFF1A2338),
      surfaceElevated: const Color(0xFF1C2640),
      border: const Color(0xFF26314A),
      textPrimary: const Color(0xFFE2E8F0),
      textSecondary: const Color(0xFF94A3B8),
      textTertiary: const Color(0xFF7C8BA1),
      textDisabled: const Color(0xFF4B5870),
      overlay: const Color(0x99000000),
      primary: a.primary,
      onPrimary: a.onPrimary,
      primaryContainer: a.primaryContainer,
      onPrimaryContainer: a.onPrimaryContainer,
      success: const Color(0xFF4ADE80),
      successBg: const Color(0xFF14301F),
      warning: const Color(0xFFFBBF24),
      warningBg: const Color(0xFF3A2A0C),
      error: const Color(0xFFF87171),
      errorBg: const Color(0xFF3B1717),
      info: const Color(0xFF38BDF8),
      infoBg: const Color(0xFF0C2A3D),
      tintRose: const Color(0xFFF472B6),
      tintRoseBg: const Color(0xFF3A1529),
      tintGreen: const Color(0xFF4ADE80),
      tintGreenBg: const Color(0xFF14301F),
      tintAmber: const Color(0xFFFBBF24),
      tintAmberBg: const Color(0xFF3A2A0C),
      tintSky: const Color(0xFF38BDF8),
      tintSkyBg: const Color(0xFF0C2A3D),
    );
  }

  List<Color> get _all => [
    background, surface, surfaceVariant, surfaceElevated, border, //
    textPrimary, textSecondary, textTertiary, textDisabled, overlay,
    primary, onPrimary, primaryContainer, onPrimaryContainer,
    success, successBg, warning, warningBg, error, errorBg, info, infoBg,
    tintRose, tintRoseBg, tintGreen, tintGreenBg, tintAmber, tintAmberBg,
    tintSky, tintSkyBg,
  ];

  static AppTokens _fromList(List<Color> c) => AppTokens(
    background: c[0],
    surface: c[1],
    surfaceVariant: c[2],
    surfaceElevated: c[3],
    border: c[4],
    textPrimary: c[5],
    textSecondary: c[6],
    textTertiary: c[7],
    textDisabled: c[8],
    overlay: c[9],
    primary: c[10],
    onPrimary: c[11],
    primaryContainer: c[12],
    onPrimaryContainer: c[13],
    success: c[14],
    successBg: c[15],
    warning: c[16],
    warningBg: c[17],
    error: c[18],
    errorBg: c[19],
    info: c[20],
    infoBg: c[21],
    tintRose: c[22],
    tintRoseBg: c[23],
    tintGreen: c[24],
    tintGreenBg: c[25],
    tintAmber: c[26],
    tintAmberBg: c[27],
    tintSky: c[28],
    tintSkyBg: c[29],
  );

  @override
  AppTokens copyWith() => this;

  /// Smooth color cross-fade when the theme changes (§7.5).
  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    final a = _all;
    final b = other._all;
    return _fromList([
      for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
    ]);
  }
}

extension AppTokensContext on BuildContext {
  /// The current theme's color tokens.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
