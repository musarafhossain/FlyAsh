import 'package:flutter/material.dart';

import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/router/nav_items.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';

/// Temporary screen for a section until its real screen is built.
class SectionPlaceholderPage extends StatelessWidget {
  const SectionPlaceholderPage({super.key, required this.item});

  final NavItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(item.text(context.l10n)),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.s4),
        children: [
          const SizedBox(height: Space.s8),
          EmptyState(
            icon: item.selectedIcon,
            title: item.text(context.l10n),
            message: context.l10n.placeholderStep(item.step),
          ),
        ],
      ),
    );
  }
}
