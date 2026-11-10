import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// One choice in an [showActionMenu].
class ActionMenuItem {
  const ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// Shown in the error colour (Delete).
  final bool destructive;
}

/// The action menu of a list row (opened by a long press): a popup next to
/// the row, at its right side, with the actions in [groups] split by thin
/// lines (e.g. [View, Edit] | [Deactivate] | [Delete]). The menu closes
/// first, then the chosen action runs.
///
/// [anchor] is the row's own context, so the menu opens where the row is.
Future<void> showActionMenu(
  BuildContext anchor, {
  required List<List<ActionMenuItem>> groups,
}) async {
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay =
      Overlay.of(anchor, rootOverlay: true).context.findRenderObject()!
          as RenderBox;
  // Top right of the menu: the row's right edge, a little below its middle.
  final at = box.localToGlobal(
    Offset(box.size.width, box.size.height * 0.6),
    ancestor: overlay,
  );
  final t = anchor.tokens;
  final shown = [
    for (final g in groups)
      if (g.isNotEmpty) g,
  ];

  final chosen = await showMenu<ActionMenuItem>(
    context: anchor,
    useRootNavigator: true,
    position: RelativeRect.fromLTRB(
      at.dx,
      at.dy,
      overlay.size.width - at.dx,
      overlay.size.height - at.dy,
    ),
    constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
    color: t.surface,
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.35),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: Radii.mdAll,
      side: BorderSide(color: t.border),
    ),
    items: [
      for (final (i, group) in shown.indexed) ...[
        if (i > 0) const PopupMenuDivider(),
        for (final item in group)
          PopupMenuItem<ActionMenuItem>(
            value: item,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: Space.s5),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: item.destructive ? t.error : t.textSecondary,
                ),
                const SizedBox(width: Space.s5),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      color: item.destructive ? t.error : t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
  chosen?.onSelected();
}

/// ⋮ button in an app bar (detail pages) that opens [showActionMenu] with
/// the page's actions, just below the button.
class ActionMenuButton extends StatelessWidget {
  const ActionMenuButton({
    super.key,
    required this.tooltip,
    required this.groups,
    this.enabled = true,
  });

  final String tooltip;
  final List<List<ActionMenuItem>> groups;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (button) => IconButton(
      tooltip: tooltip,
      onPressed: enabled ? () => showActionMenu(button, groups: groups) : null,
      icon: const Icon(Icons.more_vert),
    ),
  );
}
