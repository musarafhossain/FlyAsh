import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../widgets/labours_tab.dart';

/// The two tabs of the Labours section. Each has its own URL.
enum LabourSectionTab {
  labours('/labours'),
  wages('/labours/wages');

  const LabourSectionTab(this.path);
  final String path;
}

/// Labours section (03-AppFlow §7): tabs Labours · Wages.
///   /labours        → labour list
///   /labours/wages  → monthly wage sheet for every labour (F13)
class LaboursPage extends StatelessWidget {
  const LaboursPage({super.key, required this.tab});

  final LabourSectionTab tab;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: LabourSectionTab.values.length,
      initialIndex: tab.index,
      child: Scaffold(
        appBar: AppBar(
          leading: ShellMenuButton.maybe(context),
          title: Text(l.navLabours),
          actions: const [AppBarActions()],
          bottom: TabBar(
            onTap: (i) {
              if (i != tab.index) context.go(LabourSectionTab.values[i].path);
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
        body: switch (tab) {
          LabourSectionTab.labours => const LaboursTab(),
          LabourSectionTab.wages => ListView(
            padding: const EdgeInsets.all(Space.s4),
            children: [
              const SizedBox(height: Space.s8),
              EmptyState(
                icon: Icons.payments,
                title: l.navWages,
                message: l.placeholderStep('F13'),
              ),
            ],
          ),
        },
      ),
    );
  }
}
