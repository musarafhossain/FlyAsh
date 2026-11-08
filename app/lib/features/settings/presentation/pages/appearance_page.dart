import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/status_pill.dart';
import '../widgets/accent_swatch.dart';
import 'settings_page.dart';

/// Settings → Appearance (04-UI-UX §8.1): theme mode, accent color, font
/// size and a live preview. Every change applies instantly; mode and accent
/// are also saved to the account (PreferencesSync), font size on the device.
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.appearance)),
      body: PageBody(
        maxWidth: 720,
        children: [
          _Caption(l.themeMode),
          _Narrow(
            child: Row(
              children: [
                for (final (i, mode) in [
                  ThemeMode.light,
                  ThemeMode.dark,
                  ThemeMode.system,
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: Space.s3),
                  Expanded(
                    child: _ModeTile(
                      mode: mode,
                      label: themeModeLabel(l, mode),
                      selected: settings.mode == mode,
                      onTap: () => controller.setMode(mode),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _Caption(l.accentColor),
          // One row on every screen size: the 5 swatches share the width.
          _Narrow(
            child: Row(
              children: [
                for (final accent in AccentColor.values)
                  Expanded(
                    child: AccentSwatch(
                      accent: accent,
                      label: accentLabel(l, accent),
                      selected: settings.accent == accent,
                      onTap: () => controller.setAccent(accent),
                      width: null,
                    ),
                  ),
              ],
            ),
          ),
          _Caption(l.fontSize),
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              for (final (i, label) in [
                l.fontSmall,
                l.fontDefault,
                l.fontLarge,
                l.fontExtraLarge,
              ].indexed)
                ButtonSegment(
                  value: kFontScales[i],
                  label: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {settings.fontScale},
            onSelectionChanged: (s) => controller.setFontScale(s.first),
          ),
          _Caption(l.preview),
          const _Preview(),
          const SizedBox(height: Space.s4),
          Align(
            child: TextButton.icon(
              onPressed: controller.reset,
              icon: const Icon(Icons.restart_alt),
              label: Text(l.resetToDefault),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accent name in the current language.
String accentLabel(AppLocalizations l, AccentColor accent) => switch (accent) {
  AccentColor.blue => l.accentBlue,
  AccentColor.brick => l.accentBrick,
  AccentColor.emerald => l.accentEmerald,
  AccentColor.violet => l.accentViolet,
  AccentColor.slate => l.accentSlate,
};

/// Keeps a row of choices at a comfortable width on tablets and desktops.
class _Narrow extends StatelessWidget {
  const _Narrow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: child,
    ),
  );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.s5, bottom: Space.s3),
    child: Text(
      text.toUpperCase(),
      style: AppTypography.micro.copyWith(
        color: context.tokens.textTertiary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// Light / Dark / System tile with a tiny drawing of the screen.
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(
            color: selected ? t.primary : t.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.s2),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.4,
                  child: ClipRRect(
                    borderRadius: Radii.smAll,
                    child: switch (mode) {
                      ThemeMode.light => const _MiniScreen(dark: false),
                      ThemeMode.dark => const _MiniScreen(dark: true),
                      ThemeMode.system => const Row(
                        children: [
                          Expanded(child: _MiniScreen(dark: false)),
                          Expanded(child: _MiniScreen(dark: true)),
                        ],
                      ),
                    },
                  ),
                ),
                const SizedBox(height: Space.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? Icons.check_circle : icon,
                      size: 16,
                      color: selected ? t.primary : t.textSecondary,
                    ),
                    const SizedBox(width: Space.s1),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: selected ? t.primary : t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny light or dark "screen" with the current accent.
class _MiniScreen extends ConsumerWidget {
  const _MiniScreen({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeControllerProvider.select((s) => s.accent));
    final t = AppTokens.of(accent, dark ? Brightness.dark : Brightness.light);
    return Container(
      color: t.background,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: dark ? t.primaryContainer : t.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: t.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live mini dashboard drawn with the current theme (§8.1 PREVIEW).
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            icon: Icons.currency_rupee,
            label: l.previewHeroLabel,
            value: '₹48,500',
            caption: l.previewHeroCaption,
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(l.previewPaid, tone: StatusTone.success),
              StatusPill(l.previewPartial, tone: StatusTone.warning),
              StatusPill(l.previewDue, tone: StatusTone.error),
            ],
          ),
          const SizedBox(height: Space.s3),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: Text(l.previewButton),
                ),
              ),
              const SizedBox(width: Space.s2),
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: Text(l.cancel)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
