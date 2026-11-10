import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../l10n/locale_controller.dart';
import '../router/app_bar_actions.dart' show popoverStyle;
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

const double _width = 264;

/// 文A language button (app bar, Login): opens a popover like Appearance
/// and the account menu, with a card per language; the chosen one is
/// tinted and ticked. Changing it switches the UI text and the API
/// messages together.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.iconOnly = false});

  /// Only the 文A icon (narrow app bars on phones).
  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider);
    final l = context.l10n;
    final t = context.tokens;
    return MenuAnchor(
      alignmentOffset: const Offset(-_width, Space.s1),
      style: popoverStyle(context, width: _width),
      menuChildren: [
        SizedBox(
          width: _width,
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.language,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  l.languageHint,
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: Space.s3),
                for (final (value, badge, name) in [
                  ('en', 'EN', l.languageEnglish),
                  ('bn', 'বা', l.languageBengali),
                ]) ...[
                  if (value == 'bn') const SizedBox(height: Space.s2),
                  // Builder: a context inside the menu, to close it.
                  Builder(
                    builder: (menuContext) => _LanguageOption(
                      badge: badge,
                      name: name,
                      selected: code == value,
                      onTap: () {
                        MenuController.maybeOf(menuContext)?.close();
                        ref.read(localeProvider.notifier).setLocale(value);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      builder: (context, menu, _) => InkWell(
        borderRadius: Radii.fullAll,
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
        child: Tooltip(
          message: l.language,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 20),
                if (!iconOnly) ...[
                  const SizedBox(width: 6),
                  Text(code == 'bn' ? l.languageBengali : 'EN'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One language as a selectable card: badge, name, and a tick when chosen.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.badge,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String badge;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? t.primaryContainer : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(
            color: selected ? t.primary : t.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.s3,
              vertical: Space.s3,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? t.primary : t.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.label.copyWith(
                      color: selected ? t.onPrimary : t.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.bodyStrong.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected ? t.primary : t.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
