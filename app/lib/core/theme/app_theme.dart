import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Builds the Material theme for one accent in one mode (10 combinations).
abstract final class AppTheme {
  static ThemeData build(AccentColor accent, Brightness brightness) {
    final t = AppTokens.of(accent, brightness);
    final textTheme = AppTypography.textTheme(t.textPrimary, t.textSecondary);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primaryContainer,
      onPrimaryContainer: t.onPrimaryContainer,
      secondary: t.primary,
      onSecondary: t.onPrimary,
      secondaryContainer: t.primaryContainer,
      onSecondaryContainer: t.onPrimaryContainer,
      error: t.error,
      onError: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF0B1120),
      errorContainer: t.errorBg,
      onErrorContainer: t.error,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceContainerLowest: t.background,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surfaceVariant,
      surfaceContainerHighest: t.surfaceVariant,
      outline: t.border,
      outlineVariant: t.border,
      shadow: const Color(0x0F0F172A),
      scrim: t.overlay,
      inverseSurface: t.textPrimary,
      onInverseSurface: t.surface,
      inversePrimary: t.primaryContainer,
    );

    const buttonShape = RoundedRectangleBorder(borderRadius: Radii.mdAll);
    const buttonSize = Size(64, kMinTouchTarget);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      fontFamily: AppTypography.latin,
      fontFamilyFallback: AppTypography.fallback,
      textTheme: textTheme,
      extensions: [t],
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: t.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.border),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, kMinTouchTarget),
          shape: buttonShape,
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: 14,
        ),
        hintStyle: AppTypography.body.copyWith(color: t.textTertiary),
        labelStyle: AppTypography.label.copyWith(color: t.textSecondary),
        border: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: t.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: t.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: t.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceVariant,
        selectedColor: t.primaryContainer,
        labelStyle: AppTypography.label.copyWith(color: t.textPrimary),
        side: BorderSide(color: t.border),
        shape: const RoundedRectangleBorder(borderRadius: Radii.fullAll),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: t.primaryContainer,
          selectedForegroundColor: t.onPrimaryContainer,
          side: BorderSide(color: t.border),
          minimumSize: const Size(48, kMinTouchTarget),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: t.surface),
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.primary),
    );
  }
}
