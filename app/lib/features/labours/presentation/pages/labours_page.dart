import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../wages/presentation/widgets/wages_tab.dart';
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
///   /labours/wages  → monthly wage sheet for every labour (?month=)
class LaboursPage extends StatelessWidget {
  const LaboursPage({super.key, required this.tab, this.month});

  final LabourSectionTab tab;

  /// Wages tab: `?month=YYYY-MM`.
  final String? month;

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
          LabourSectionTab.wages => WagesTab(initialMonth: month),
        },
      ),
    );
  }
}
