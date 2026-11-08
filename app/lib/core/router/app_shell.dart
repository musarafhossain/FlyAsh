import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../config/env.dart';
import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../theme/theme_controller.dart';
import '../widgets/list_items.dart';
import 'app_bar_actions.dart';
import 'nav_items.dart';

/// Responsive app frame (04-UI-UX §11, 03-AppFlow §3):
/// - phone  (< 600):     bottom bar (4 sections + More → drawer)
/// - tablet (600–1023):  navigation rail (4 sections + More → drawer)
/// - desktop (≥ 1024):   persistent sidebar with every section (collapsible)
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _collapsed = false;

  int get _index => widget.shell.currentIndex;

  void _go(int index) {
    // Tapping the current section again goes back to its first screen.
    widget.shell.goBranch(index, initialLocation: index == _index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final body = widget.shell;

    // Android back on a section root: go Home first, then leave the app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _go(0);
      },
      child: _buildLayout(width, body),
    );
  }

  Widget _buildLayout(double width, Widget body) {
    if (width >= Breakpoints.expanded) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          children: [
            _Sidebar(
              selected: _index,
              collapsed: _collapsed,
              onSelect: _go,
              onToggle: () => setState(() => _collapsed = !_collapsed),
            ),
            VerticalDivider(width: 1, color: context.tokens.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    final primary = kPrimaryBranches;
    final selectedPrimary = primary.indexOf(_index);
    // A drawer section (Customers, Reports …) is open: no bottom/rail item is selected.
    final inDrawerSection = selectedPrimary < 0;
    void onTap(int i) => _go(primary[i]);

    final drawer = _AppDrawer(selected: _index, onSelect: _go);
    final scoped = ShellScope(openDrawer: _openDrawer, child: body);

    if (width >= Breakpoints.medium) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: drawer,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: inDrawerSection ? null : selectedPrimary,
              onDestinationSelected: onTap,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: Space.s3),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                ),
              ),
              destinations: [
                for (final i in primary)
                  NavigationRailDestination(
                    icon: Icon(kNavItems[i].icon),
                    selectedIcon: Icon(kNavItems[i].selectedIcon),
                    label: Text(kNavItems[i].text(context.l10n)),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: context.tokens.border),
            Expanded(child: scoped),
          ],
        ),
      );
    }

    // NavigationBar always needs a selected index; when a drawer section is
    // open the selection is drawn as unselected.
    final t = context.tokens;
    final bar = NavigationBar(
      selectedIndex: inDrawerSection ? 0 : selectedPrimary,
      onDestinationSelected: onTap,
      destinations: [
        for (final i in primary)
          NavigationDestination(
            icon: Icon(kNavItems[i].icon),
            selectedIcon: Icon(
              inDrawerSection ? kNavItems[i].icon : kNavItems[i].selectedIcon,
            ),
            label: kNavItems[i].text(context.l10n),
          ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: drawer,
      body: scoped,
      bottomNavigationBar: inDrawerSection
          ? NavigationBarTheme(
              data: NavigationBarTheme.of(context).copyWith(
                indicatorColor: Colors.transparent,
                iconTheme: WidgetStatePropertyAll(
                  IconThemeData(color: t.textSecondary),
                ),
                labelTextStyle: WidgetStatePropertyAll(
                  AppTypography.micro.copyWith(color: t.textSecondary),
                ),
              ),
              child: bar,
            )
          : bar,
    );
  }
}

/// Gives screens inside the shell access to the drawer (phone/tablet only).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.openDrawer, required super.child});

  final VoidCallback openDrawer;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

/// ☰ button for the app bar's left side. Shows only where there is a
/// drawer (phone/tablet); on desktop the sidebar is always visible.
/// Usage: `AppBar(leading: ShellMenuButton.maybe(context))`.
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static Widget? maybe(BuildContext context) {
    final scope = ShellScope.maybeOf(context);
    return scope == null ? null : ShellMenuButton(onPressed: scope.openDrawer);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: context.l10n.menu,
    icon: const Icon(Icons.menu),
  );
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final light = Theme.of(context).brightness == Brightness.light;
    final headerBg = light ? t.primary : t.primaryContainer;
    final headerFg = light ? t.onPrimary : t.onPrimaryContainer;

    return Drawer(
      backgroundColor: t.surface,
      child: Column(
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: light
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Material(
              color: headerBg,
              child: InkWell(
                // Header → My profile
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).go('/profile');
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Space.s5,
                    MediaQuery.paddingOf(context).top + Space.s5,
                    Space.s3,
                    Space.s5,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Space.s1),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final user = ref.watch(
                              authControllerProvider.select((s) => s.user),
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Env.appName,
                                  style: AppTypography.h2.copyWith(
                                    color: headerFg,
                                  ),
                                ),
                                if (user != null)
                                  Text(
                                    '${user.name} · ${user.phone}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: headerFg,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      _ThemeToggle(color: headerFg),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: Space.s2,
                horizontal: Space.s3,
              ),
              children: [
                for (final group in NavGroup.values) ...[
                  _GroupCaption(navGroupLabel(context.l10n, group)),
                  for (var i = 0; i < kNavItems.length; i++)
                    if (kNavItems[i].group == group)
                      _MenuTile(
                        item: kNavItems[i],
                        selected: i == selected,
                        onTap: () => onSelect(i),
                      ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              Space.s3,
              Space.s2,
              Space.s3,
              Space.s3,
            ),
            child: _LogoutTile(),
          ),
        ],
      ),
    );
  }
}

/// Sun/moon button: switches Light ↔ Dark without opening Settings (§8.2.7).
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l = context.l10n;
    return IconButton(
      tooltip: dark ? l.themeLight : l.themeDark,
      color: color,
      onPressed: () => ref
          .read(themeControllerProvider.notifier)
          .setMode(dark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

/// Desktop sidebar (≥ 1024 px):
///   top    — logo, app + factory name, collapse button
///   middle — sections under group captions; selected = tinted pill with an
///            accent bar, hover highlight
///   bottom — the logged-in user (→ My profile) and Log out
/// Collapsed it keeps only icons (with tooltips).
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.collapsed,
    required this.onSelect,
    required this.onToggle,
  });

  final int selected;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  static const double expandedWidth = 264;
  static const double collapsedWidth = 80;

  /// Below this width only icons fit (also while the sidebar animates).
  static const double _minWidthForLabels = 200;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: collapsed ? collapsedWidth : expandedWidth,
      color: t.surface,
      child: SafeArea(
        right: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = collapsed || c.maxWidth < _minWidthForLabels;
            return Column(
              children: [
                _SidebarHeader(
                  compact: compact,
                  collapsed: collapsed,
                  onToggle: onToggle,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.s3,
                      0,
                      Space.s3,
                      Space.s3,
                    ),
                    children: [
                      for (final group in NavGroup.values) ...[
                        if (compact && group != NavGroup.values.first)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.s3,
                              vertical: Space.s2,
                            ),
                            child: Divider(height: 1, color: t.border),
                          )
                        else if (!compact)
                          _GroupCaption(navGroupLabel(l, group)),
                        for (var i = 0; i < kNavItems.length; i++)
                          if (kNavItems[i].group == group)
                            _SidebarTile(
                              item: kNavItems[i],
                              selected: i == selected,
                              compact: compact,
                              onTap: () => onSelect(i),
                            ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: t.border),
                _SidebarFooter(compact: compact),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidebarHeader extends ConsumerWidget {
  const _SidebarHeader({
    required this.compact,
    required this.collapsed,
    required this.onToggle,
  });

  final bool compact;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final factoryName = ref.watch(factorySettingsProvider).value?.factoryName;

    final logo = Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Radii.mdAll,
        border: Border.all(color: t.border),
      ),
      child: Image.asset('assets/images/logo.png'),
    );
    final toggle = IconButton(
      onPressed: onToggle,
      tooltip: collapsed ? l.expandMenu : l.collapseMenu,
      style: IconButton.styleFrom(foregroundColor: t.textSecondary),
      icon: Icon(
        collapsed
            ? Icons.keyboard_double_arrow_right
            : Icons.keyboard_double_arrow_left,
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, Space.s3, 0, Space.s1),
        child: Column(
          children: [
            logo,
            const SizedBox(height: Space.s1),
            toggle,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.s4,
        Space.s4,
        Space.s2,
        Space.s3,
      ),
      child: Row(
        children: [
          logo,
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Env.appName,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: AppTypography.h2.copyWith(color: t.textPrimary),
                ),
                Text(
                  factoryName ?? l.appTagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
          toggle,
        ],
      ),
    );
  }
}

/// Small upper-case group caption ("DAILY WORK").
class _GroupCaption extends StatelessWidget {
  const _GroupCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.s3, 14, Space.s3, 6),
    child: Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      style: AppTypography.micro.copyWith(
        color: context.tokens.textTertiary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = item.text(context.l10n);
    final fg = selected ? t.onPrimaryContainer : t.textSecondary;

    final tile = Material(
      color: selected ? t.primaryContainer : Colors.transparent,
      borderRadius: Radii.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // One translucent hover tint for both states. (Switching the hover
        // color to Colors.transparent on select painted the tile black: the
        // highlight keeps its opacity and takes the new color's RGB.)
        hoverColor: t.textPrimary.withValues(alpha: 0.06),
        child: SizedBox(
          height: 40,
          child: Stack(
            children: [
              // Accent bar on the selected item
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: 0,
                top: selected ? 9 : 20,
                bottom: selected ? 9 : 20,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: selected ? t.primary : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (!compact) const SizedBox(width: Space.s4),
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: 22,
                      color: selected ? t.primary : fg,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: selected
                                ? t.onPrimaryContainer
                                : t.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Semantics(
        selected: selected,
        button: true,
        label: compact ? label : null,
        child: compact
            ? Tooltip(
                message: label,
                preferBelow: false,
                waitDuration: const Duration(milliseconds: 300),
                child: tile,
              )
            : tile,
      ),
    );
  }
}

/// The logged-in user (→ My profile) and the Log out button.
class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final name = user?.name ?? l.myProfile;
    void openProfile() => GoRouter.of(context).go('/profile');

    final logout = IconButton(
      onPressed: () => confirmLogout(context, ref),
      tooltip: l.logout,
      style: IconButton.styleFrom(foregroundColor: t.error),
      icon: const Icon(Icons.logout),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s2),
        child: Column(
          children: [
            Tooltip(
              message: l.myProfile,
              child: InkWell(
                onTap: openProfile,
                customBorder: const CircleBorder(),
                child: InitialsAvatar(name, size: 40),
              ),
            ),
            const SizedBox(height: Space.s2),
            logout,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Space.s2),
      child: Material(
        color: t.surfaceVariant,
        borderRadius: Radii.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openProfile,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.s3,
              Space.s2,
              Space.s1,
              Space.s2,
            ),
            child: Row(
              children: [
                InitialsAvatar(name, size: 40),
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
                      Text(
                        user?.phone ?? l.viewProfile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                logout,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// Below this width only the icon fits (e.g. a very narrow drawer).
  static const _minWidthForLabel = 120.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, constraints.maxWidth < _minWidthForLabel),
    );
  }

  Widget _build(BuildContext context, bool compact) {
    final t = context.tokens;
    final fg = selected ? t.onPrimaryContainer : t.textSecondary;
    final tile = Material(
      color: selected ? t.primaryContainer : Colors.transparent,
      borderRadius: Radii.fullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.fullAll,
        child: Container(
          height: kMinTouchTarget,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : Space.s4),
          alignment: compact ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: fg,
              ),
              if (!compact) ...[
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Text(
                    item.text(context.l10n),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: selected ? t.onPrimaryContainer : t.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        selected: selected,
        child: compact
            ? Tooltip(message: item.text(context.l10n), child: tile)
            : tile,
      ),
    );
  }
}

/// "Log out" with a confirmation (drawer bottom).
class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;

    Future<void> logout() => confirmLogout(context, ref);

    return LayoutBuilder(
      builder: (context, c) {
        final iconOnly = c.maxWidth < 120;
        final tile = InkWell(
          onTap: logout,
          borderRadius: Radii.fullAll,
          child: SizedBox(
            height: kMinTouchTarget,
            child: Row(
              mainAxisAlignment: iconOnly
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!iconOnly) const SizedBox(width: Space.s4),
                Icon(Icons.logout, size: 22, color: t.error),
                if (!iconOnly) ...[
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Text(
                      l.logout,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: t.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        return Semantics(
          button: true,
          label: l.logout,
          excludeSemantics: true,
          child: iconOnly ? Tooltip(message: l.logout, child: tile) : tile,
        );
      },
    );
  }
}
