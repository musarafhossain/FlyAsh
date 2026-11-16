import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../update/domain/app_update.dart';
import '../../../update/presentation/update_controller.dart';
import '../../../update/presentation/update_widgets.dart';

/// Installed version and build (`version: 1.0.0+1` in pubspec).
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Settings → About & Updates: logo, version, build, server, and
/// "Check for updates" (03-AppFlow §12).
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  bool _checking = false;

  Future<void> _check() async {
    final l = context.l10n;
    setState(() => _checking = true);
    final AppUpdate update;
    try {
      update = await ref.read(updateControllerProvider.notifier).check();
    } on Failure catch (f) {
      if (mounted) {
        setState(() => _checking = false);
        showMessage(context, failureText(context, f));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _checking = false);
    final platform = ref.read(updatePlatformProvider);
    if (!update.updateAvailable || platform == null) {
      showMessage(context, l.upToDate);
    } else if (!update.forceUpdate) {
      // (A forced update replaces the whole app by itself: UpdateGate.)
      await showUpdateDialog(context, update, platform);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: Space.s4),
          OutlinedButton.icon(
            key: const Key('checkForUpdates'),
            onPressed: _checking ? null : _check,
            icon: _checking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_outlined),
            label: Text(l.checkForUpdates),
          ),
        ],
      ),
    );
  }
}
