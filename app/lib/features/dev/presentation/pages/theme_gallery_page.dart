import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../settings/presentation/widgets/accent_swatch.dart';

/// Debug-only screen to check the theme in every combination
/// (5 accents × light/dark × font sizes) and at every screen width.
class ThemeGalleryPage extends ConsumerWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme gallery')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = Breakpoints.gutter(constraints.maxWidth);
          return SingleChildScrollView(
            padding: EdgeInsets.all(gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Theme mode',
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.settings_suggest_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {settings.mode},
                        onSelectionChanged: (s) => controller.setMode(s.first),
                      ),
                    ),
                    _Section(
                      title: 'Accent color',
                      child: Wrap(
                        spacing: Space.s4,
                        runSpacing: Space.s3,
                        children: [
                          for (final accent in AccentColor.values)
                            AccentSwatch(
                              accent: accent,
                              label: accent.label,
                              selected: settings.accent == accent,
                              onTap: () => controller.setAccent(accent),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Font size',
                      child: SegmentedButton<double>(
                        segments: [
                          for (final (i, label) in [
                            'S',
                            'Default',
                            'L',
                            'XL',
                          ].indexed)
                            ButtonSegment(
                              value: kFontScales[i],
                              label: Text(label),
                            ),
                        ],
                        selected: {settings.fontScale},
                        onSelectionChanged: (s) =>
                            controller.setFontScale(s.first),
                      ),
                    ),
                    _Section(
                      title: 'Hero card',
                      child: Container(
                        padding: const EdgeInsets.all(Space.s5),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? t.primary
                              : t.primaryContainer,
                          borderRadius: Radii.lgAll,
                        ),
                        child: Builder(
                          builder: (context) {
                            final fg =
                                Theme.of(context).brightness == Brightness.light
                                ? t.onPrimary
                                : t.onPrimaryContainer;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Sales · আজকের বিক্রি",
                                  style: AppTypography.caption.copyWith(
                                    color: fg,
                                  ),
                                ),
                                const SizedBox(height: Space.s1),
                                Text(
                                  '₹48,500',
                                  style: AppTypography.display.copyWith(
                                    color: fg,
                                    fontFeatures: AppTypography.tabular,
                                  ),
                                ),
                                Text(
                                  '6 sales · ↑ 8% vs yesterday',
                                  style: AppTypography.caption.copyWith(
                                    color: fg,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    _Section(
                      title: 'Status colors',
                      child: Wrap(
                        spacing: Space.s2,
                        runSpacing: Space.s2,
                        children: [
                          _Pill('Paid', t.success, t.successBg),
                          _Pill('Partial', t.warning, t.warningBg),
                          _Pill('Due', t.error, t.errorBg),
                          _Pill('Booked', t.info, t.infoBg),
                          _Pill('Inactive', t.textSecondary, t.surfaceVariant),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Typography',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Display ₹12,400',
                            style: AppTypography.display.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'H1 Dashboard · ড্যাশবোর্ড',
                            style: AppTypography.h1.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'H2 Sales · বিক্রি',
                            style: AppTypography.h2.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'H3 Quick actions',
                            style: AppTypography.h3.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'Title Rahim Traders',
                            style: AppTypography.title.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'Body: The quick brown fox · দ্রুত বাদামি শিয়াল',
                            style: AppTypography.body.copyWith(
                              color: t.textPrimary,
                            ),
                          ),
                          Text(
                            'Caption 08 Nov 2026',
                            style: AppTypography.caption.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                          Text(
                            'MICRO LABEL',
                            style: AppTypography.micro.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Buttons & input',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: Space.s3,
                            runSpacing: Space.s3,
                            children: [
                              FilledButton(
                                onPressed: () {},
                                child: const Text('Save'),
                              ),
                              FilledButton.tonal(
                                onPressed: () {},
                                child: const Text('Secondary'),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('View all'),
                              ),
                              const FilledButton(
                                onPressed: null,
                                child: Text('Disabled'),
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.s4),
                          const TextField(
                            decoration: InputDecoration(
                              labelText: 'Customer name',
                              hintText: 'Rahim Sheikh',
                            ),
                          ),
                          const SizedBox(height: Space.s3),
                          const TextField(
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              errorText: 'Phone number format is invalid',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'Color tokens',
                      child: Wrap(
                        spacing: Space.s2,
                        runSpacing: Space.s2,
                        children: [
                          for (final (name, color) in [
                            ('background', t.background),
                            ('surface', t.surface),
                            ('surfaceVariant', t.surfaceVariant),
                            ('border', t.border),
                            ('textPrimary', t.textPrimary),
                            ('textSecondary', t.textSecondary),
                            ('primary', t.primary),
                            ('primaryContainer', t.primaryContainer),
                            ('tintRose', t.tintRoseBg),
                            ('tintGreen', t.tintGreenBg),
                            ('tintAmber', t.tintAmberBg),
                            ('tintSky', t.tintSkyBg),
                          ])
                            _TokenTile(name: name, color: color),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: controller.reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset to default'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: context.tokens.textTertiary,
            ),
          ),
          const SizedBox(height: Space.s2),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.fg, this.bg);

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.fullAll),
      child: Text(label, style: AppTypography.micro.copyWith(color: fg)),
    );
  }
}

class _TokenTile extends StatelessWidget {
  const _TokenTile({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Container(
      width: 140,
      padding: const EdgeInsets.all(Space.s2),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border.all(color: context.tokens.border),
        borderRadius: Radii.mdAll,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: Radii.smAll,
              border: Border.all(color: context.tokens.border),
            ),
          ),
          const SizedBox(width: Space.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
                Text(
                  hex,
                  style: AppTypography.caption.copyWith(
                    color: context.tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
