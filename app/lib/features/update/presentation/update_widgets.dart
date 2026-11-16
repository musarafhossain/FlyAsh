import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/app_update.dart';
import 'update_controller.dart';

/// App update UI (03-AppFlow §12, 04-UI-UX "Update dialog / screen").

/// "Version 1.2.0" + release notes.
class _Details extends StatelessWidget {
  const _Details(this.update);
  final AppUpdate update;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final notes = update.releaseNotes?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.updateVersion(update.latestVersion ?? '?'),
          style: AppTypography.label.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: Space.s2),
          Text(
            notes,
            style: AppTypography.body.copyWith(color: t.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Progress bar, the Android hint, or the error line.
class _Status extends StatelessWidget {
  const _Status(this.run, {this.center = false});
  final UpdateRun run;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    if (run.busy) {
      final known = run.progress >= 0;
      return Column(
        key: const Key('updateProgress'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: Radii.smAll,
            child: LinearProgressIndicator(
              value: known ? run.progress : null,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: Space.s2),
          Text(
            known
                ? l.updateDownloading('${(run.progress * 100).round()}')
                : l.updateDownloadingNoSize,
            style: AppTypography.caption.copyWith(color: t.textSecondary),
          ),
        ],
      );
    }
    if (run.failed) {
      return Text(
        l.updateFailed,
        key: const Key('updateError'),
        textAlign: center ? TextAlign.center : null,
        style: AppTypography.body.copyWith(color: t.error),
      );
    }
    if (run.platform == UpdatePlatform.android) {
      return Text(
        l.updateInstallHint,
        textAlign: center ? TextAlign.center : null,
        style: AppTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Optional update: notes · Later / Update now (Reload on the web). While
/// downloading: progress + Cancel.
Future<void> showUpdateDialog(
  BuildContext context,
  AppUpdate update,
  UpdatePlatform platform,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _UpdateDialog(update: update, platform: platform),
);

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update, required this.platform});
  final AppUpdate update;
  final UpdatePlatform platform;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  late final _run = UpdateRun(widget.update, widget.platform)
    ..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = dialogButtonStyle(context);
    final web = widget.platform == UpdatePlatform.web;
    return PopScope(
      canPop: !_run.busy,
      child: AlertDialog(
        key: const Key('updateDialog'),
        title: Text(l.updateAvailableTitle, style: dialogTitleStyle(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Details(widget.update),
            const SizedBox(height: Space.s4),
            _Status(_run),
          ],
        ),
        actions: [
          OutlinedButton(
            style: style,
            onPressed: _run.busy
                ? _run.cancel
                : () => Navigator.of(context).pop(),
            child: Text(_run.busy ? l.cancel : l.updateLater),
          ),
          FilledButton(
            style: style,
            onPressed: _run.busy ? null : () => unawaited(_run.start()),
            child: Text(
              web
                  ? l.updateReload
                  : _run.failed
                  ? l.retry
                  : l.updateNow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Forced update: a full-screen page in place of the app; no way past it.
class UpdateRequiredPage extends StatefulWidget {
  const UpdateRequiredPage({
    super.key,
    required this.update,
    required this.platform,
  });

  final AppUpdate update;
  final UpdatePlatform platform;

  @override
  State<UpdateRequiredPage> createState() => _UpdateRequiredPageState();
}

class _UpdateRequiredPageState extends State<UpdateRequiredPage> {
  late final _run = UpdateRun(widget.update, widget.platform)
    ..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final web = widget.platform == UpdatePlatform.web;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('updateRequired'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.s6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: t.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_outlined,
                          size: 44,
                          color: t.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.s5),
                    Text(
                      l.updateRequiredTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: Space.s2),
                    Text(
                      l.updateRequiredMessage,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.s5),
                    Container(
                      padding: const EdgeInsets.all(Space.s4),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: t.border),
                      ),
                      child: _Details(widget.update),
                    ),
                    const SizedBox(height: Space.s4),
                    _Status(_run, center: true),
                    const SizedBox(height: Space.s4),
                    FilledButton.icon(
                      key: const Key('updateRequiredButton'),
                      onPressed: _run.busy
                          ? null
                          : () => unawaited(_run.start()),
                      icon: Icon(web ? Icons.refresh : Icons.download),
                      label: Text(
                        web
                            ? l.updateReload
                            : _run.failed
                            ? l.retry
                            : l.updateButton,
                      ),
                    ),
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

/// Wraps the whole app: checks once at start; a forced update replaces the
/// app with [UpdateRequiredPage], an optional one opens the dialog.
/// A failed check is ignored (the app works offline of updates).
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  /// An optional update waiting for the splash screen to finish (a page
  /// change would close a dialog opened on top of the splash).
  AppUpdate? _pending;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    if (ref.read(updateCheckEnabledProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final update = await ref.read(updateControllerProvider.notifier).check();
      if (!mounted || !update.updateAvailable || update.forceUpdate) return;
      if (ref.read(updatePlatformProvider) == null) return;
      _pending = update;
      final router = ref.read(routerProvider);
      _router = router;
      router.routerDelegate.addListener(_onRoute);
      _onRoute();
    } catch (_) {
      // No network or server: try again next start.
    }
  }

  void _onRoute() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPending());

  void _showPending() {
    final update = _pending;
    final router = _router;
    final platform = ref.read(updatePlatformProvider);
    if (!mounted || update == null || router == null || platform == null) {
      return;
    }
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (path.isEmpty || path == '/splash' || context == null) return;
    _pending = null;
    router.routerDelegate.removeListener(_onRoute);
    unawaited(showUpdateDialog(context, update, platform));
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateControllerProvider);
    final platform = ref.watch(updatePlatformProvider);
    if (update != null && update.forceUpdate && platform != null) {
      return UpdateRequiredPage(update: update, platform: platform);
    }
    return widget.child;
  }
}
