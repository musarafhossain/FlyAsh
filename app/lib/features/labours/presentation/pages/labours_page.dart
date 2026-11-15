import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/controls.dart';
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
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navLabours),
        actions: const [AppBarActions()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The same sliding pill tabs as Sales (All / Instant / Booking).
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SegmentedTabs<LabourSectionTab>(
                  segments: {
                    LabourSectionTab.labours: l.navLabours,
                    LabourSectionTab.wages: l.navWages,
                  },
                  selected: tab,
                  onChanged: (t) {
                    if (t != tab) context.go(t.path);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (tab) {
              LabourSectionTab.labours => const LaboursTab(),
              LabourSectionTab.wages => WagesTab(initialMonth: month),
            },
          ),
        ],
      ),
    );
  }
}
