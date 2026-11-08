import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';

/// Debug-only screen showing every core widget with sample data,
/// arranged like a real screen so layouts can be checked at any width.
class WidgetGalleryPage extends StatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  State<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends State<WidgetGalleryPage> {
  String _tab = 'all';
  int _month = 10;
  String? _lastAction;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  void _did(String action) => setState(() => _lastAction = action);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('Widget gallery')),
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: EdgeInsets.all(Breakpoints.gutter(c.maxWidth)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroCard(
                    icon: Icons.currency_rupee,
                    label: "Today's sales",
                    value: Fmt.money('48500.00'),
                    caption: '6 sales · profit ${Fmt.money('15200.00')}',
                    onTap: () => _did('hero'),
                  ),
                  const SizedBox(height: Space.s3),
                  KpiRow(
                    children: [
                      KpiChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Total due',
                        value: Fmt.money('603316.00'),
                        tint: KpiTint.rose,
                      ),
                      const KpiChip(
                        icon: Icons.local_shipping_outlined,
                        label: 'Deliveries today',
                        value: '3',
                        tint: KpiTint.sky,
                      ),
                      const KpiChip(
                        icon: Icons.groups_outlined,
                        label: 'Present today',
                        value: '13 / 15',
                        tint: KpiTint.green,
                      ),
                      KpiChip(
                        icon: Icons.receipt_long_outlined,
                        label: 'Month expenses',
                        value: Fmt.money('18250.00'),
                        tint: KpiTint.amber,
                      ),
                    ],
                  ),
                  const SectionHeader('Quick actions'),
                  QuickActionGrid(
                    children: [
                      QuickActionTile(
                        icon: Icons.add_shopping_cart,
                        label: 'New sale',
                        onTap: () => _did('new sale'),
                      ),
                      QuickActionTile(
                        icon: Icons.event_available,
                        label: 'New booking',
                        onTap: () => _did('booking'),
                      ),
                      QuickActionTile(
                        icon: Icons.how_to_reg_outlined,
                        label: 'Attendance',
                        onTap: () => _did('attendance'),
                      ),
                      QuickActionTile(
                        icon: Icons.receipt_outlined,
                        label: 'Add expense',
                        onTap: () => _did('expense'),
                      ),
                    ],
                  ),
                  const SectionHeader('Tabs & period'),
                  SegmentedTabs<String>(
                    segments: const {
                      'all': 'All',
                      'instant': 'Instant',
                      'booking': 'Booking',
                    },
                    selected: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                  const SizedBox(height: Space.s3),
                  PeriodSelector(
                    label: '${_months[_month]} 2026',
                    onPrevious: _month > 0
                        ? () => setState(() => _month--)
                        : null,
                    onNext: _month < 10 ? () => setState(() => _month++) : null,
                  ),
                  SectionHeader(
                    'Recent sales',
                    actionLabel: 'View all',
                    onAction: () => _did('view all'),
                  ),
                  EntityListTile(
                    leading: const InitialsAvatar('Rahim Traders'),
                    title: 'Rahim Traders',
                    subtitle: 'INV-000101 · ${Fmt.date('2026-11-08')}',
                    trailing: Fmt.money('33500.00'),
                    status: 'Partial',
                    statusTone: StatusPill.toneFor('partial'),
                    onTap: () => _did('sale'),
                  ),
                  const SizedBox(height: Space.s2),
                  EntityListTile(
                    leading: const InitialsAvatar('Nazrul Islam'),
                    title: 'Nazrul Islam',
                    subtitle:
                        'INV-000102 · Booking · delivery ${Fmt.date('2026-11-15')}',
                    meta: 'Bongaon station road',
                    trailing: Fmt.money('19500.00'),
                    status: 'Booked',
                    statusTone: StatusPill.toneFor('booked'),
                  ),
                  const SizedBox(height: Space.s2),
                  EntityListTile(
                    leading: const InitialsAvatar('Habib Enterprise'),
                    title: 'Habib Enterprise',
                    subtitle: '9876543210',
                    trailing: Fmt.money('4500.00'),
                    trailingTone: t.error,
                    status: 'Due',
                    statusTone: StatusTone.error,
                  ),
                  const SectionHeader('Summary'),
                  LayoutBuilder(
                    builder: (context, c2) {
                      final wide = c2.maxWidth >= Breakpoints.medium;
                      final summary = LineItemSummaryCard(
                        title: 'INV-000101',
                        lines: [
                          SummaryLine('Subtotal', Fmt.money('32500.00')),
                          SummaryLine(
                            'Transport',
                            Fmt.money('1500.00'),
                            icon: Icons.local_shipping_outlined,
                          ),
                          SummaryLine(
                            'Discount',
                            '− ${Fmt.money('500.00')}',
                            color: t.error,
                          ),
                          SummaryLine(
                            'Total',
                            Fmt.money('33500.00'),
                            emphasis: true,
                            dividerBefore: true,
                          ),
                          SummaryLine(
                            'Profit',
                            Fmt.money('12500.00'),
                            color: t.success,
                          ),
                          SummaryLine('Paid', Fmt.money('10000.00')),
                          SummaryLine(
                            'Due',
                            Fmt.money('23500.00'),
                            color: t.error,
                            emphasis: true,
                          ),
                        ],
                      );
                      final ring = AppCard(
                        child: Center(
                          child: ProgressRing(
                            value: 13 / 15,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '13 / 15',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                                Text(
                                  'present today',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: summary),
                                const SizedBox(width: Space.s3),
                                Expanded(child: ring),
                              ],
                            )
                          : Column(
                              children: [
                                summary,
                                const SizedBox(height: Space.s3),
                                ring,
                              ],
                            );
                    },
                  ),
                  const SectionHeader('States'),
                  AppCard(
                    child: EmptyState(
                      icon: Icons.point_of_sale,
                      title: 'No sales yet',
                      message: 'Your sales will appear here.',
                      actionLabel: 'New sale',
                      onAction: () => _did('empty action'),
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  AppCard(
                    child: ErrorState(
                      message: 'No internet connection',
                      onRetry: () => _did('retry'),
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  const SkeletonList(count: 2),
                  const SizedBox(height: Space.s3),
                  Wrap(
                    spacing: Space.s3,
                    runSpacing: Space.s3,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Delete INV-000101?',
                            message: 'It will be removed from all reports.',
                            confirmLabel: 'Delete',
                            destructive: true,
                          );
                          _did(ok ? 'confirmed' : 'cancelled');
                        },
                        child: const Text('Confirm dialog'),
                      ),
                      const StatusPill(
                        'Paid',
                        tone: StatusTone.success,
                        dot: true,
                      ),
                    ],
                  ),
                  if (_lastAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s3),
                      child: Text(
                        'Last action: $_lastAction',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
