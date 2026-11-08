import 'package:flutter/material.dart';

/// The 5 accent color themes (04-UI-UX §5.2). The names match the API
/// values of `users.accent_color`.
enum AccentColor {
  blue('Royal Blue'),
  brick('Brick Terracotta'),
  emerald('Emerald Green'),
  violet('Deep Violet'),
  slate('Ash Slate');

  const AccentColor(this.label);
  final String label;

  static AccentColor fromName(String? name) => AccentColor.values.firstWhere(
    (a) => a.name == name,
    orElse: () => AccentColor.blue,
  );
}

/// The 4 accent tokens for one accent in one mode.
class AccentPalette {
  const AccentPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
}

/// Raw color values. Widgets never use these directly; they read
/// `context.tokens` (see app_tokens.dart).
abstract final class AppColors {
  static const _darkOnPrimary = Color(0xFF0B1120);

  /// Accent palettes, light and dark (contrast checked against WCAG AA).
  static AccentPalette accent(AccentColor accent, Brightness brightness) {
    final light = brightness == Brightness.light;
    switch (accent) {
      case AccentColor.blue:
        return light
            ? const AccentPalette(
                primary: Color(0xFF1A56F0),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFE8EFFF),
                onPrimaryContainer: Color(0xFF0B2A80),
              )
            : const AccentPalette(
                primary: Color(0xFF7AA2FF),
                onPrimary: _darkOnPrimary,
                primaryContainer: Color(0xFF16264D),
                onPrimaryContainer: Color(0xFFD6E2FF),
              );
      case AccentColor.brick:
        return light
            ? const AccentPalette(
                primary: Color(0xFFC2410C),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFFDEDE4),
                onPrimaryContainer: Color(0xFF6B210A),
              )
            : const AccentPalette(
                primary: Color(0xFFFF9467),
                onPrimary: _darkOnPrimary,
                primaryContainer: Color(0xFF3D1F14),
                onPrimaryContainer: Color(0xFFFFDCCB),
              );
      case AccentColor.emerald:
        return light
            ? const AccentPalette(
                primary: Color(0xFF047857),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFE3F6EE),
                onPrimaryContainer: Color(0xFF053D2E),
              )
            : const AccentPalette(
                primary: Color(0xFF4ADE9F),
                onPrimary: _darkOnPrimary,
                primaryContainer: Color(0xFF0F3327),
                onPrimaryContainer: Color(0xFFC8F2DE),
              );
      case AccentColor.violet:
        return light
            ? const AccentPalette(
                primary: Color(0xFF6D28D9),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFF0E9FD),
                onPrimaryContainer: Color(0xFF3A1478),
              )
            : const AccentPalette(
                primary: Color(0xFFB394FF),
                onPrimary: _darkOnPrimary,
                primaryContainer: Color(0xFF2A1C4D),
                onPrimaryContainer: Color(0xFFE6DBFF),
              );
      case AccentColor.slate:
        return light
            ? const AccentPalette(
                primary: Color(0xFF475569),
                onPrimary: Colors.white,
                primaryContainer: Color(0xFFEEF1F5),
                onPrimaryContainer: Color(0xFF1E293B),
              )
            : const AccentPalette(
                primary: Color(0xFFA5B4C8),
                onPrimary: _darkOnPrimary,
                primaryContainer: Color(0xFF232D3D),
                onPrimaryContainer: Color(0xFFDCE3EC),
              );
    }
  }
}
