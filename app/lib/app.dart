import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/preferences_sync.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/router/back_guard.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// Root widget: applies the saved theme (mode, accent, font size).
/// Navigation: go_router (core/router). Language: English / Bengali (lib/l10n).
class FlyAshApp extends ConsumerStatefulWidget {
  const FlyAshApp({super.key});

  @override
  ConsumerState<FlyAshApp> createState() => _FlyAshAppState();
}

class _FlyAshAppState extends ConsumerState<FlyAshApp> {
  @override
  void initState() {
    super.initState();
    // Before the router starts listening, so the browser's back button
    // first closes an open drawer / dialog (BackGuard).
    BackGuard.instance.attach();
  }

  @override
  void dispose() {
    BackGuard.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Keeps language/theme in sync with the account while the app runs.
    ref.watch(preferencesSyncProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: Env.appName,
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          child: Theme(
            data: AppTheme.withResponsiveSnackBar(
              Theme.of(context),
              media.size.width,
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
