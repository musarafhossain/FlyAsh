import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/page_layout.dart';

/// Installed version and build (`version: 1.0.0+1` in pubspec).
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Settings → About: logo, version, build, server. "Check for updates"
/// is added here in F18.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final info = ref.watch(packageInfoProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutApp)),
      body: PageBody(
        children: [
          const SizedBox(height: Space.s4),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              semanticLabel: Env.appName,
            ),
          ),
          const SizedBox(height: Space.s3),
          Text(
            Env.appName,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: t.textPrimary),
          ),
          Text(
            l.appTagline,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: Space.s6),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.verified_outlined,
                  label: l.version,
                  value: info?.version ?? '…',
                ),
                InfoRow(
                  icon: Icons.tag,
                  label: l.buildNumber,
                  value: info?.buildNumber ?? '…',
                ),
                InfoRow(
                  icon: Icons.dns_outlined,
                  label: l.server,
                  value: Env.apiBaseUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
