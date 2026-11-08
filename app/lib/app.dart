import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/splash/presentation/pages/splash_page.dart';

/// Root widget: applies the saved theme (mode, accent, font size).
/// The router (F4) and localization (F5) are added in later steps.
class FlyAshApp extends ConsumerWidget {
  const FlyAshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings.accent, Brightness.light),
      darkTheme: AppTheme.build(settings.accent, Brightness.dark),
      themeMode: settings.mode,
      themeAnimationDuration: const Duration(milliseconds: 200),
      builder: (context, child) {
        // Font size setting on top of the device text scale.
        final media = MediaQuery.of(context);
        final scale = media.textScaler.scale(1) * settings.fontScale;
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: const SplashPage(),
    );
  }
}
