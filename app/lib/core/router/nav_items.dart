import 'package:flutter/material.dart';

/// One section of the app. The order is the branch order of the router.
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.step,
    this.primary = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Plan step that builds the real screen (shown on placeholders).
  final String step;

  /// Shown in the phone bottom bar / tablet rail (the rest live in the drawer).
  final bool primary;
}

/// All sections (03-AppFlow §3). Labels are translated in F5.
const List<NavItem> kNavItems = [
  NavItem(
    path: '/home',
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    step: 'F15',
    primary: true,
  ),
  NavItem(
    path: '/sales',
    label: 'Sales',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    step: 'F10',
    primary: true,
  ),
  NavItem(
    path: '/attendance',
    label: 'Attendance',
    icon: Icons.how_to_reg_outlined,
    selectedIcon: Icons.how_to_reg,
    step: 'F12',
    primary: true,
  ),
  NavItem(
    path: '/expenses',
    label: 'Expenses',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    step: 'F14',
    primary: true,
  ),
  NavItem(
    path: '/customers',
    label: 'Customers',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    step: 'F9',
  ),
  NavItem(
    path: '/products',
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    step: 'F8',
  ),
  NavItem(
    path: '/labours',
    label: 'Labours',
    icon: Icons.engineering_outlined,
    selectedIcon: Icons.engineering,
    step: 'F12',
  ),
  NavItem(
    path: '/wages',
    label: 'Wages',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    step: 'F13',
  ),
  NavItem(
    path: '/reports',
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    step: 'F16',
  ),
  NavItem(
    path: '/users',
    label: 'Users',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts,
    step: 'F7',
  ),
  NavItem(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    step: 'F7',
  ),
];

/// Branch indexes of the primary items, in order.
final List<int> kPrimaryBranches = [
  for (var i = 0; i < kNavItems.length; i++)
    if (kNavItems[i].primary) i,
];
