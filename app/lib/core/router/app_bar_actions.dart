import 'dart:math' as math;

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
    final width = popoverWidth(context, _appearanceWidth);
    return MenuAnchor(
      style: popoverStyle(context, width: width),
      menuChildren: [
        Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(themeControllerProvider);
            final controller = ref.read(themeControllerProvider.notifier);
            return SizedBox(
              width: width,
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
        SizedBox(
          width: width,
          child: MenuItemButton(
            leadingIcon: const Icon(Icons.tune),
            onPressed: () => context.go('/settings/appearance'),
            child: Text(l.moreAppearanceSettings),
          ),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: l.appearance,
        onPressed: () => togglePopover(context, menu, width),
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
      style: popoverStyle(context, width: _accountWidth),
      menuChildren: [
        // Who is logged in
        SizedBox(
          width: _accountWidth,
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Row(
              children: [
                const UserIconAvatar(size: 44),
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
        SizedBox(
          width: _accountWidth,
          child: MenuItemButton(
            leadingIcon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            child: Text(l.myProfile),
          ),
        ),
        SizedBox(
          width: _accountWidth,
          child: MenuItemButton(
            leadingIcon: const Icon(Icons.lock_outline),
            onPressed: () => context.go('/profile/password'),
            child: Text(l.changePassword),
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          width: _accountWidth,
          child: MenuItemButton(
            leadingIcon: Icon(Icons.logout, color: t.error),
            onPressed: () => confirmLogout(context, ref),
            child: Text(l.logout, style: TextStyle(color: t.error)),
          ),
        ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: l.account,
        child: Semantics(
          button: true,
          label: l.account,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => togglePopover(context, menu, _accountWidth),
            child: const Padding(
              padding: EdgeInsets.all(Space.s1),
              child: UserIconAvatar(size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

const double _appearanceWidth = 320;
const double _accountWidth = 264;

/// Round avatar with a person icon (the account button and its popover).
class UserIconAvatar extends StatelessWidget {
  const UserIconAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: size * 0.62, color: t.onPrimaryContainer),
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

/// [preferred] width, but never wider than the screen minus a 16 px gap on
/// each side (phones).
double popoverWidth(BuildContext context, double preferred) =>
    math.min(preferred, MediaQuery.sizeOf(context).width - 2 * Space.s4);

/// Opens (or closes) a popover below its button: right-aligned with the
/// button when there is room, and always at least 16 px from both screen
/// edges. [anchor] is the button's context (inside the MenuAnchor).
void togglePopover(BuildContext anchor, MenuController menu, double width) {
  if (menu.isOpen) {
    menu.close();
    return;
  }
  final box = anchor.findRenderObject()! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero);
  final screen = MediaQuery.sizeOf(anchor).width;
  final right = topLeft.dx + box.size.width;
  final left = (right - width)
      .clamp(Space.s4, math.max(Space.s4, screen - Space.s4 - width))
      .toDouble();
  menu.open(position: Offset(left - topLeft.dx, box.size.height + Space.s1));
}

/// Rounded, bordered popover of a fixed [width] (open it with
/// [togglePopover], which places it below the button).
MenuStyle popoverStyle(BuildContext context, {required double width}) {
  final t = context.tokens;
  return MenuStyle(
    alignment: AlignmentDirectional.bottomEnd,
    minimumSize: WidgetStatePropertyAll(Size(width, 0)),
    maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
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
