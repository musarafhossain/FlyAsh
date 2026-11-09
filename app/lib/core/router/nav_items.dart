import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Groups shown as captions in the sidebar and the drawer.
enum NavGroup { daily, business, admin }

/// One section of the app. The order is the branch order of the router.
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.step,
    required this.group,
    this.primary = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Plan step that builds the real screen (shown on placeholders).
  final String step;

  final NavGroup group;

  /// Shown in the phone bottom bar / tablet rail (the rest live in the drawer).
  final bool primary;

  /// Label in the current language ([label] is the English fallback).
  String text(AppLocalizations l) => switch (path) {
    '/home' => l.navHome,
    '/sales' => l.navSales,
    '/attendance' => l.navAttendance,
    '/expenses' => l.navExpenses,
    '/customers' => l.navCustomers,
    '/products' => l.navProducts,
    '/labours' => l.navLabours,
    '/reports' => l.navReports,
    '/users' => l.navUsers,
    '/settings' => l.navSettings,
    _ => label,
  };
}

/// All sections (03-AppFlow §3). UI text comes from [NavItem.text].
const List<NavItem> kNavItems = [
  NavItem(
    path: '/home',
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    step: 'F15',
    group: NavGroup.daily,
    primary: true,
  ),
  NavItem(
    path: '/sales',
    label: 'Sales',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    step: 'F10',
    group: NavGroup.daily,
    primary: true,
  ),
  NavItem(
    path: '/attendance',
    label: 'Attendance',
    icon: Icons.how_to_reg_outlined,
    selectedIcon: Icons.how_to_reg,
    step: 'F12',
    group: NavGroup.daily,
    primary: true,
  ),
  NavItem(
    path: '/expenses',
    label: 'Expenses',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    step: 'F14',
    group: NavGroup.daily,
    primary: true,
  ),
  NavItem(
    path: '/customers',
    label: 'Customers',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    step: 'F9',
    group: NavGroup.business,
  ),
  NavItem(
    path: '/products',
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    step: 'F8',
    group: NavGroup.business,
  ),
  NavItem(
    path: '/labours',
    label: 'Labours',
    icon: Icons.engineering_outlined,
    selectedIcon: Icons.engineering,
    step: 'F12', // Wages is a tab inside Labours (F13)
    group: NavGroup.business,
  ),
  NavItem(
    path: '/reports',
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    step: 'F16',
    group: NavGroup.business,
  ),
  NavItem(
    path: '/users',
    label: 'Users',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts,
    step: 'F7',
    group: NavGroup.admin,
  ),
  NavItem(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    step: 'F7',
    group: NavGroup.admin,
  ),
];

/// Branch indexes of the primary items, in order.
final List<int> kPrimaryBranches = [
  for (var i = 0; i < kNavItems.length; i++)
    if (kNavItems[i].primary) i,
];

/// Caption of a group in the current language.
String navGroupLabel(AppLocalizations l, NavGroup group) => switch (group) {
  NavGroup.daily => l.navGroupDaily,
  NavGroup.business => l.navGroupBusiness,
  NavGroup.admin => l.navGroupAdmin,
};
