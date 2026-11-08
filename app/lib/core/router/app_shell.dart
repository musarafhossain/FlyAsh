import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../config/env.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
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
    // "More" is selected when the current section lives in the drawer.
    final selected = selectedPrimary >= 0 ? selectedPrimary : primary.length;
    void onTap(int i) => i < primary.length ? _go(primary[i]) : _openDrawer();

    if (width >= Breakpoints.medium) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _AppDrawer(selected: _index, onSelect: _go),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
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
                    label: Text(kNavItems[i].label),
                  ),
                const NavigationRailDestination(
                  icon: Icon(Icons.menu),
                  label: Text('More'),
                ),
              ],
            ),
            VerticalDivider(width: 1, color: context.tokens.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(selected: _index, onSelect: _go),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: onTap,
        destinations: [
          for (final i in primary)
            NavigationDestination(
              icon: Icon(kNavItems[i].icon),
              selectedIcon: Icon(kNavItems[i].selectedIcon),
              label: kNavItems[i].label,
            ),
          const NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
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
                    child: Text(
                      Env.appName,
                      style: AppTypography.h2.copyWith(color: headerFg),
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
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 40, height: 40),
                  if (!collapsed) ...[
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Text(
                        Env.appName,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: AppTypography.h2.copyWith(color: t.textPrimary),
                      ),
                    ),
                  ],
                ],
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
              padding: const EdgeInsets.all(Space.s3),
              child: IconButton(
                onPressed: onToggle,
                tooltip: collapsed ? 'Expand menu' : 'Collapse menu',
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

  @override
  Widget build(BuildContext context) {
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
                    item.label,
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
        child: compact ? Tooltip(message: item.label, child: tile) : tile,
      ),
    );
  }
}
