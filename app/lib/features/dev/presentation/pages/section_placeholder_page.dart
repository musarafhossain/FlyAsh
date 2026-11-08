import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: Text(item.label),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.s4),
        children: [
          const SizedBox(height: Space.s8),
          EmptyState(
            icon: item.selectedIcon,
            title: item.label,
            message: 'This screen is built in step ${item.step}.',
          ),
          if (kDebugMode && item.path == '/settings')
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.s3,
              runSpacing: Space.s3,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/dev/theme'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Theme gallery'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/dev/widgets'),
                  icon: const Icon(Icons.widgets_outlined),
                  label: const Text('Widget gallery'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
