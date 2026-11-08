import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../config/env.dart';
import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../widgets/state_views.dart';
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
            child: Container(
              width: double.infinity,
              color: headerBg,
              padding: EdgeInsets.fromLTRB(
                Space.s5,
                MediaQuery.paddingOf(context).top + Space.s5,
                Space.s5,
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
                              style: AppTypography.h2.copyWith(color: headerFg),
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
                ],
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
                for (var i = 0; i < kNavItems.length; i++)
                  _MenuTile(
                    item: kNavItems[i],
                    selected: i == selected,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(Space.s3, 0, Space.s3, Space.s3),
            child: _LogoutTile(),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 76 : 240,
      color: t.surface,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s3,
                Space.s4,
                Space.s3,
                Space.s3,
              ),
              // The name only shows when there is room (not mid-animation).
              child: LayoutBuilder(
                builder: (context, c) => Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    if (!collapsed && c.maxWidth >= 120) ...[
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Text(
                          Env.appName,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: AppTypography.h2.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                children: [
                  for (var i = 0; i < kNavItems.length; i++)
                    _MenuTile(
                      item: kNavItems[i],
                      selected: i == selected,
                      compact: collapsed,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3),
              child: _LogoutTile(compact: collapsed),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s3),
              child: IconButton(
                onPressed: onToggle,
                tooltip: collapsed
                    ? context.l10n.expandMenu
                    : context.l10n.collapseMenu,
                icon: Icon(
                  collapsed
                      ? Icons.keyboard_double_arrow_right
                      : Icons.keyboard_double_arrow_left,
                ),
              ),
            ),
          ],
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
    this.compact = false,
  });

  final NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  /// Below this width only the icon fits (e.g. while the sidebar animates).
  static const _minWidthForLabel = 120.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, compact || constraints.maxWidth < _minWidthForLabel),
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

/// "Log out" with a confirmation (drawer bottom and desktop sidebar).
class _LogoutTile extends ConsumerWidget {
  const _LogoutTile({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;

    Future<void> logout() async {
      final ok = await showConfirmDialog(
        context,
        title: l.logoutConfirmTitle,
        message: l.logoutConfirmMessage,
        confirmLabel: l.logout,
        destructive: true,
      );
      if (ok) await ref.read(authControllerProvider.notifier).logout();
    }

    return LayoutBuilder(
      builder: (context, c) {
        final iconOnly = compact || c.maxWidth < 120;
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
