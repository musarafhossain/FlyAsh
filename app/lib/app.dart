import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'features/splash/presentation/pages/splash_page.dart';

/// Root widget.
///
/// F0 (setup) uses a basic Material theme and a placeholder page.
/// The real theme system (F1), router (F4) and localization (F5) replace them.
class FlyAshApp extends StatelessWidget {
  const FlyAshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A56F0),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
