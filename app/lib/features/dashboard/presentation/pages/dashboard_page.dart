import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../sales/presentation/widgets/sale_list_items.dart';
import '../../../settings/data/settings_repository_impl.dart';
import '../../data/dashboard_repository_impl.dart';
import '../../domain/dashboard.dart';

/// Home (03-AppFlow §4, 04-UI-UX "Dashboard"): greeting, Today's sales
/// (with profit), Total due · Deliveries today · Present today · Month
/// expenses, quick actions, recent sales. Every card opens its screen.
/// Pull to refresh; it also refreshes whenever Home is shown again.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardData? _data;
  Object? _error;
  GoRouter? _router;
  bool _wasHome = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Home stays alive in the background (shell); reload when it comes back.
    _router = ref.read(routerProvider);
    _router!.routeInformationProvider.addListener(_onRoute);
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRoute);
    super.dispose();
  }

  void _onRoute() {
    final isHome = _router!.routeInformationProvider.value.uri.path == '/home';
    if (isHome && !_wasHome) _load();
    _wasHome = isHome;
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ref.read(dashboardRepositoryProvider).get();
      if (mounted) setState(() => _data = data);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = _data;
    final overdue = data?.overdueDeliveries ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navHome),
        actions: [
          IconButton(
            tooltip: l.upcomingDeliveries,
            onPressed: () => context.go('/sales/upcoming'),
            icon: Badge.count(
              count: overdue,
              isLabelVisible: overdue > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const AppBarActions(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            Breakpoints.gutter(MediaQuery.sizeOf(context).width),
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: data == null
                    ? (_error != null
                          ? ErrorState(
                              message: failureText(context, _error!),
                              onRetry: _load,
                            )
                          : const _Loading())
                    : _Body(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SkeletonBox(height: 56),
      SizedBox(height: Space.s3),
      SkeletonBox(height: 120, radius: Radii.lg),
      SizedBox(height: Space.s3),
      SkeletonList(count: 3),
    ],
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final d = data;

    final kpis = KpiRow(
      children: [
        KpiChip(
          icon: Icons.account_balance_wallet_outlined,
          label: l.totalDue,
          value: Fmt.money(d.totalDue),
          tint: KpiTint.rose,
          onTap: () => context.go('/customers?filter=due'),
        ),
        KpiChip(
          icon: Icons.local_shipping_outlined,
          label: d.overdueDeliveries > 0
              ? l.deliveriesTodayOverdue('${d.overdueDeliveries}')
              : l.deliveriesToday,
          value: '${d.deliveriesToday}',
          tint: KpiTint.sky,
          onTap: () => context.go('/sales/upcoming'),
        ),
        KpiChip(
          icon: Icons.how_to_reg_outlined,
          label: l.presentToday,
          value: '${d.presentToday}/${d.laboursTotal}',
          tint: KpiTint.green,
          onTap: () => context.go('/attendance'),
        ),
        KpiChip(
          icon: Icons.receipt_long_outlined,
          label: l.monthExpenses,
          value: Fmt.money(d.monthExpenses),
          tint: KpiTint.amber,
          onTap: () => context.go('/expenses'),
        ),
      ],
    );

    final quick = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.quickActions),
        QuickActionGrid(
          children: [
            QuickActionTile(
              icon: Icons.point_of_sale_outlined,
              label: l.newSale,
              onTap: () => context.go('/sales/new?type=instant'),
            ),
            QuickActionTile(
              icon: Icons.event_available_outlined,
              label: l.newBooking,
              onTap: () => context.go('/sales/new?type=booking'),
            ),
            QuickActionTile(
              icon: Icons.how_to_reg_outlined,
              label: l.navAttendance,
              onTap: () => context.go('/attendance'),
            ),
            QuickActionTile(
              icon: Icons.receipt_long_outlined,
              label: l.addExpense,
              onTap: () => context.go('/expenses/new'),
            ),
          ],
        ),
      ],
    );

    final recent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.recentSales,
          actionLabel: l.viewAll,
          onAction: () => context.go('/sales'),
        ),
        if (d.recentSales.isEmpty)
          AppCard(
            child: Text(
              l.noSalesYet,
              style: AppTypography.body.copyWith(
                color: context.tokens.textTertiary,
              ),
            ),
          ),
        if (d.recentSales.isNotEmpty)
          ListGroup(
            children: [
              for (final s in d.recentSales)
                SaleTile(
                  sale: s,
                  showCustomer: true,
                  onTap: () => context.go('/sales/${s.id}'),
                ),
            ],
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Greeting(date: d.date),
        const SizedBox(height: Space.s4),
        HeroCard(
          icon: Icons.trending_up,
          label: l.todaysSales,
          value: Fmt.money(d.todaySalesAmount),
          caption: l.todaysSalesCaption(
            '${d.todaySalesCount}',
            Fmt.money(d.todayProfit),
          ),
          onTap: () => context.go('/sales?period=today'),
        ),
        const SizedBox(height: Space.s3),
        kpis,
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: quick),
              const SizedBox(width: Space.s5),
              Expanded(child: recent),
            ],
          )
        else ...[
          quick,
          recent,
        ],
        const SizedBox(height: Space.s6),
      ],
    );
  }
}

/// "Good morning, Test Owner" · factory name · today's date.
class _Greeting extends ConsumerWidget {
  const _Greeting({required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final factory = ref.watch(factorySettingsProvider).value?.factoryName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l.goodMorning
        : (hour < 17 ? l.goodAfternoon : l.goodEvening);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.caption.copyWith(color: t.textSecondary),
              ),
              Text(
                user?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h2.copyWith(color: t.textPrimary),
              ),
              Text(
                [?factory, Fmt.date(date)].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
