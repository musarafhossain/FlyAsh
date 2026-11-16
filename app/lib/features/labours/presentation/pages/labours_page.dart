import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../widgets/labours_tab.dart';

/// Labours section (03-AppFlow §7.1): the labour list only (no tabs).
/// A labour's wages are on their page (⋮ → Wage details / Pay wage); the
/// month's wages for everyone are in Reports → Wages.
class LaboursPage extends StatelessWidget {
  const LaboursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navLabours),
        actions: const [AppBarActions()],
      ),
      body: const LaboursTab(),
    );
  }
}
