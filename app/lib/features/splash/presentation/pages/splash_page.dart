import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Shown while the app checks the saved session (03-AppFlow §1).
/// The router leaves this page as soon as the auth state is known.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 112,
              height: 112,
              semanticLabel: 'FlyAsh logo',
            ),
            const SizedBox(height: Space.s4),
            Text(
              Env.appName,
              style: AppTypography.h1.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: Space.s1),
            Text(
              context.l10n.appTagline,
              style: AppTypography.body.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: Space.s6),
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
