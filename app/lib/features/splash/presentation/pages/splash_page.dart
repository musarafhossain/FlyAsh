import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../dev/presentation/pages/theme_gallery_page.dart';
import '../../../dev/presentation/pages/widget_gallery_page.dart';

/// Placeholder start screen for F0 (setup).
/// F6 turns this into the real splash (theme, session and update checks).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  logoAsset,
                  width: 160,
                  height: 160,
                  semanticLabel: 'FlyAsh logo',
                ),
                const SizedBox(height: 24),
                Text(
                  Env.appName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Brick factory management', style: textTheme.bodyLarge),
                const SizedBox(height: 32),
                Text(
                  'API: ${Env.apiBaseUrl}',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ThemeGalleryPage(),
                      ),
                    ),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Theme gallery'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WidgetGalleryPage(),
                      ),
                    ),
                    icon: const Icon(Icons.widgets_outlined),
                    label: const Text('Widget gallery'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
