import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';

/// The two tabs of the Labours section. Each has its own URL.
enum LaboursTab {
  labours('/labours'),
  wages('/labours/wages');

  const LaboursTab(this.path);
  final String path;
}

/// Labours section (03-AppFlow §7): tabs Labours · Wages.
///   /labours        → labour list (F12)
///   /labours/wages  → monthly wage sheet for every labour (F13)
class LaboursPage extends StatelessWidget {
  const LaboursPage({super.key, required this.tab});

  final LaboursTab tab;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: LaboursTab.values.length,
      initialIndex: tab.index,
      child: Scaffold(
        appBar: AppBar(
          leading: ShellMenuButton.maybe(context),
          title: Text(l.navLabours),
          actions: const [AppBarActions()],
          bottom: TabBar(
            onTap: (i) {
              if (i != tab.index) context.go(LaboursTab.values[i].path);
            },
            tabs: [
              Tab(
                icon: const Icon(Icons.engineering_outlined),
                text: l.navLabours,
              ),
              Tab(icon: const Icon(Icons.payments_outlined), text: l.navWages),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(Space.s4),
          children: [
            const SizedBox(height: Space.s8),
            switch (tab) {
              LaboursTab.labours => EmptyState(
                icon: Icons.engineering,
                title: l.navLabours,
                message: l.placeholderStep('F12'),
              ),
              LaboursTab.wages => EmptyState(
                icon: Icons.payments,
                title: l.navWages,
                message: l.placeholderStep('F13'),
              ),
            },
          ],
        ),
      ),
    );
  }
}
