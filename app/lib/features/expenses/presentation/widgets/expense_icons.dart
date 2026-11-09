import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';

/// Icon keys a category can use (stored in `expense_categories.icon`).
const Map<String, IconData> kExpenseIcons = {
  'utensils': Icons.restaurant_outlined,
  'wrench': Icons.build_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'zap': Icons.bolt_outlined,
  'truck': Icons.local_shipping_outlined,
  'ticket': Icons.confirmation_number_outlined,
  'home': Icons.home_work_outlined,
  'water': Icons.water_drop_outlined,
  'phone': Icons.phone_android_outlined,
  'tools': Icons.handyman_outlined,
  'gift': Icons.card_giftcard_outlined,
  'circle-dot': Icons.radio_button_checked,
};

IconData expenseIcon(String? key) =>
    kExpenseIcons[key] ?? Icons.receipt_long_outlined;

/// Category icon in a tinted square.
class ExpenseIcon extends StatelessWidget {
  const ExpenseIcon(this.iconKey, {super.key, this.size = 40});

  final String? iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.tintRoseBg, borderRadius: Radii.mdAll),
      child: Icon(expenseIcon(iconKey), size: size * 0.55, color: t.tintRose),
    );
  }
}
