import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale_summary.dart';
import '../widgets/sale_action_sheets.dart';
import '../widgets/sale_list_items.dart';

/// Upcoming deliveries (03-AppFlow §5.4): booked sales by delivery date,
/// overdue ones on top with an "Overdue" pill. Tap → sale detail;
/// "Mark delivered" on each row opens the same sheet as the detail page.
class UpcomingDeliveriesPage extends ConsumerStatefulWidget {
  const UpcomingDeliveriesPage({super.key});

  @override
  ConsumerState<UpcomingDeliveriesPage> createState() =>
      _UpcomingDeliveriesPageState();
}

class _UpcomingDeliveriesPageState
    extends ConsumerState<UpcomingDeliveriesPage> {
  final _list = PagedListController();

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _open(SaleSummary s) async {
    await context.push('/sales/${s.id}');
    if (mounted) _list.refresh();
  }

  Future<void> _deliver(SaleSummary s) async {
    final date = await showDeliverSheet(
      context,
      invoiceNo: s.invoiceNo,
      saleDate: s.saleDate,
      today: ref.read(businessDateProvider),
    );
    if (date == null || !mounted) return;
    try {
      final (_, message) = await ref
          .read(salesRepositoryProvider)
          .deliver(s.id, deliveredDate: date);
      if (!mounted) return;
      showMessage(context, message);
      _list.refresh();
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    }
  }

  Widget _deliverButton(SaleSummary s) => TextButton.icon(
    onPressed: () => _deliver(s),
    icon: const Icon(Icons.check_circle_outline, size: 18),
    label: Text(context.l10n.markDelivered),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(salesRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

    return Scaffold(
      appBar: AppBar(title: Text(l.upcomingDeliveries)),
      body: PagedList<SaleSummary>(
        controller: _list,
        fetch: (page) => repo.upcoming(page: page),
        empty: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: l.noUpcomingDeliveries,
          message: l.noUpcomingDeliveriesMessage,
        ),
        builder: (context, sales) => desktop
            ? SalesTable(
                sales: sales,
                showCustomer: true,
                showDelivery: true,
                onOpen: _open,
                actionBuilder: _deliverButton,
              )
            : ListGroup(
                children: [
                  for (final s in sales)
                    SaleTile(
                      sale: s,
                      showCustomer: true,
                      showDelivery: true,
                      onTap: () => _open(s),
                      action: _deliverButton(s),
                    ),
                ],
              ),
      ),
    );
  }
}
