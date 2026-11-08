import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/language_switch.dart';
import '../widgets/api_status_card.dart';

/// Placeholder start screen for F0 (setup).
/// F6 turns this into the real splash (session and update checks → login or home).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const [LanguageSwitch(), SizedBox(width: 8)],
      ),
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
                Text(l.appTagline, style: textTheme.bodyLarge),
                const SizedBox(height: 32),
                Text(
                  l.apiUrl(Env.apiBaseUrl),
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const ApiStatusCard(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l.openApp),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => context.push('/dev/theme'),
                        icon: const Icon(Icons.palette_outlined),
                        label: const Text('Theme gallery'),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/dev/widgets'),
                        icon: const Icon(Icons.widgets_outlined),
                        label: const Text('Widget gallery'),
                      ),
                    ],
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
