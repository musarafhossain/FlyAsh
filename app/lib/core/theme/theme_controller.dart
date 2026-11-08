import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/preferences.dart';
import 'app_colors.dart';

/// Font size steps (04-UI-UX §6): Small · Default · Large · Extra large.
const List<double> kFontScales = [0.9, 1.0, 1.15, 1.3];

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.accent = AccentColor.blue,
    this.fontScale = 1.0,
  });

  final ThemeMode mode;
  final AccentColor accent;
  final double fontScale;

  ThemeSettings copyWith({
    ThemeMode? mode,
    AccentColor? accent,
    double? fontScale,
  }) => ThemeSettings(
    mode: mode ?? this.mode,
    accent: accent ?? this.accent,
    fontScale: fontScale ?? this.fontScale,
  );

  /// API value of `users.theme_mode`: system | light | dark
  String get modeName => mode.name;

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.mode == mode &&
      other.accent == accent &&
      other.fontScale == fontScale;

  @override
  int get hashCode => Object.hash(mode, accent, fontScale);
}

/// Holds the appearance and caches it on the device so the right theme is
/// shown from the first frame. F5 also syncs mode and accent with the
/// account (`PUT /auth/preferences`); font size stays on the device.
class ThemeController extends Notifier<ThemeSettings> {
  static const _modeKey = 'theme.mode';
  static const _accentKey = 'theme.accent';
  static const _fontScaleKey = 'theme.font_scale';

  @override
  ThemeSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final scale = prefs.getDouble(_fontScaleKey);
    return ThemeSettings(
      mode: _modeFromName(prefs.getString(_modeKey)),
      accent: AccentColor.fromName(prefs.getString(_accentKey)),
      fontScale: kFontScales.contains(scale) ? scale! : 1.0,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await ref.read(sharedPreferencesProvider).setString(_modeKey, mode.name);
  }

  Future<void> setAccent(AccentColor accent) async {
    state = state.copyWith(accent: accent);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_accentKey, accent.name);
  }

  Future<void> setFontScale(double scale) async {
    if (!kFontScales.contains(scale)) return;
    state = state.copyWith(fontScale: scale);
    await ref.read(sharedPreferencesProvider).setDouble(_fontScaleKey, scale);
  }

  /// Applies the values saved on the user's account (from login / `/auth/me`).
  Future<void> applyFromAccount({
    String? themeMode,
    String? accentColor,
  }) async {
    if (themeMode != null) await setMode(_modeFromName(themeMode));
    if (accentColor != null) await setAccent(AccentColor.fromName(accentColor));
  }

  Future<void> reset() async {
    await setMode(ThemeMode.system);
    await setAccent(AccentColor.blue);
    await setFontScale(1.0);
  }

  static ThemeMode _modeFromName(String? name) => ThemeMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => ThemeMode.system,
  );
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
