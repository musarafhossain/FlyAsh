import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/language_switch.dart';

/// Shared frame for Login and Forgot-password screens: logo, title,
/// subtitle and a centered form (max 420 px wide), with the language
/// switch in the top-right corner.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const [
          LanguageSwitch(),
          SizedBox(width: Space.s2),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLogo) ...[
                      Image.asset(
                        'assets/images/logo.png',
                        height: 88,
                        semanticLabel: 'FlyAsh logo',
                      ),
                      const SizedBox(height: Space.s4),
                    ],
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(color: t.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: Space.s2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: Space.s6),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Basic email check for the client side (the server validates again).
bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
