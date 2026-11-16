import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Shown while the app checks the saved session (03-AppFlow §1).
/// The router leaves this page as soon as the auth state is known.
///
/// The logo sits exactly in the centre at 112 dp, like the Android launch
/// screen before it (flutter_native_splash), so the hand-over does not jump;
/// the name, tagline and loader sit below it.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const logoSize = 112.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                key: const Key('splashLogo'),
                width: logoSize,
                height: logoSize,
                semanticLabel: 'FlyAsh logo',
              ),
            ),
            // Directly under the centred logo.
            Positioned(
              left: Space.s4,
              right: Space.s4,
              top: box.maxHeight / 2 + logoSize / 2 + Space.s4,
              child: Column(
                children: [
                  Text(
                    Env.appName,
                    style: AppTypography.h1.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: Space.s1),
                  Text(
                    context.l10n.appTagline,
                    textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }
}
