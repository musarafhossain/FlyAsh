import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/settings/presentation/pages/appearance_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/widgets/accent_swatch.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../theme/theme_controller.dart';
import '../widgets/language_switch.dart';
import '../widgets/list_items.dart';
import '../widgets/state_views.dart';

/// Right side of a section's app bar:
///   [Appearance 🎨] [Language 文A] [Avatar → Profile · Change password · Log out]
/// Usage: `AppBar(actions: const [AppBarActions()])`.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < Breakpoints.medium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppearanceButton(),
        LanguageSwitch(iconOnly: phone),
        const SizedBox(width: Space.s1),
        const AccountMenu(),
        SizedBox(width: phone ? Space.s2 : Space.s4),
      ],
    );
  }
}

/// 🎨 → popover: Light / Dark / System, accent colors, link to all settings.
class AppearanceButton extends ConsumerWidget {
  const AppearanceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    return MenuAnchor(
      alignmentOffset: const Offset(0, Space.s1),
      style: popoverStyle(context),
      menuChildren: [
        Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(themeControllerProvider);
            final controller = ref.read(themeControllerProvider.notifier);
            return SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.all(Space.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.appearance,
                      style: AppTypography.title.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: Space.s3),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        for (final mode in const [
                          ThemeMode.light,
                          ThemeMode.dark,
                          ThemeMode.system,
                        ])
                          ButtonSegment(
                            value: mode,
                            tooltip: themeModeLabel(l, mode),
                            label: Text(
                              themeModeLabel(l, mode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      selected: {settings.mode},
                      onSelectionChanged: (s) => controller.setMode(s.first),
                    ),
                    const SizedBox(height: Space.s4),
                    Text(
                      l.accentColor,
                      style: AppTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    Row(
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
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.tune),
          onPressed: () => context.go('/settings/appearance'),
          child: Text(l.moreAppearanceSettings),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: l.appearance,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: const Icon(Icons.palette_outlined),
      ),
    );
  }
}

/// Avatar → popover with the user's name and Profile · Change password · Log out.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final name = user?.name ?? l.myProfile;

    return MenuAnchor(
      alignmentOffset: const Offset(0, Space.s1),
      style: popoverStyle(context),
      menuChildren: [
        // Who is logged in
        SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Row(
              children: [
                InitialsAvatar(name, size: 44),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                      if (user != null)
                        Text(
                          user.email ?? user.phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: () => context.go('/profile'),
          child: Text(l.myProfile),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.lock_outline),
          onPressed: () => context.go('/profile/password'),
          child: Text(l.changePassword),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: Icon(Icons.logout, color: t.error),
          onPressed: () => confirmLogout(context, ref),
          child: Text(l.logout, style: TextStyle(color: t.error)),
        ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: l.account,
        child: Semantics(
          button: true,
          label: l.account,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => menu.isOpen ? menu.close() : menu.open(),
            child: Padding(
              padding: const EdgeInsets.all(Space.s1),
              child: InitialsAvatar(name, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks "Log out?" and logs out when confirmed.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ok = await showConfirmDialog(
    context,
    title: l.logoutConfirmTitle,
    message: l.logoutConfirmMessage,
    confirmLabel: l.logout,
    destructive: true,
  );
  if (ok) await ref.read(authControllerProvider.notifier).logout();
}

/// Rounded, bordered popover look shared by the app bar menus.
MenuStyle popoverStyle(BuildContext context) {
  final t = context.tokens;
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(t.surfaceElevated),
    elevation: const WidgetStatePropertyAll(8),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(vertical: Space.s1),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: t.border),
      ),
    ),
  );
}
