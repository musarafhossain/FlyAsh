import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// One choice in an [showActionSheet].
class SheetAction {
  const SheetAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// Shown in the error colour (e.g. Delete, Deactivate).
  final bool destructive;
}

/// Bottom sheet opened by a long press on a list row: the record at the top
/// ([leading] + [title] / [subtitle]) and its actions below. The sheet
/// closes first, then the chosen action runs.
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  Widget? leading,
  required List<SheetAction> actions,
}) async {
  final chosen = await showModalBottomSheet<SheetAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    // Above the bottom navigation bar too, like any phone menu.
    useRootNavigator: true,
    builder: (context) {
      final t = context.tokens;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s5,
                0,
                Space.s5,
                Space.s3,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading,
                    const SizedBox(width: Space.s3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final a in actions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.s5,
                ),
                leading: Icon(
                  a.icon,
                  color: a.destructive ? t.error : t.textSecondary,
                ),
                title: Text(
                  a.label,
                  style: AppTypography.body.copyWith(
                    color: a.destructive ? t.error : t.textPrimary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(a),
              ),
            const SizedBox(height: Space.s2),
          ],
        ),
      );
    },
  );
  chosen?.onSelected();
}
