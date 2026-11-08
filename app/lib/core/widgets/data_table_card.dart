import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// One column of a [DataTableCard]. [flex] sets its share of the width.
class TableColumnDef {
  const TableColumnDef(this.label, {this.flex = 1, this.alignEnd = false});

  final String label;
  final int flex;

  /// Right-align (amounts, status).
  final bool alignEnd;
}

/// Simple desktop table in a card (04-UI-UX §11: tables on desktop):
/// a header row and tappable rows. Cells are widgets, one per column.
class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.onTapRow,
  });

  final List<TableColumnDef> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onTapRow;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget line(List<Widget> cells) => Row(
      children: [
        for (var i = 0; i < columns.length; i++)
          Expanded(
            flex: columns[i].flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s2),
              child: Align(
                alignment: columns[i].alignEnd
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: cells[i],
              ),
            ),
          ),
      ],
    );

    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: BorderSide(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: t.surfaceVariant,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.s2,
              vertical: Space.s3,
            ),
            child: line([
              for (final c in columns)
                Text(
                  c.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: t.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ]),
          ),
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) Divider(height: 1, color: t.border),
            InkWell(
              onTap: onTapRow == null ? null : () => onTapRow!(r),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s2,
                    vertical: Space.s2,
                  ),
                  child: line(rows[r]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Plain table cell text (one line, ellipsis).
class CellText extends StatelessWidget {
  const CellText(this.text, {super.key, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (strong ? AppTypography.bodyStrong : AppTypography.body).copyWith(
        color: strong ? t.textPrimary : t.textSecondary,
      ),
    );
  }
}
