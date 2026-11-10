import 'package:flutter/material.dart';

import '../../../../core/widgets/list_items.dart';

/// An icon that fits a category typed by the user, from words in it
/// ("Labour Tiffin" → food, "Diesel" → fuel …); a receipt otherwise.
IconData expenseIcon(String category) {
  final c = category.toLowerCase();
  bool has(List<String> words) => words.any(c.contains);
  if (has(['tiffin', 'food', 'tea', 'snack', 'lunch', 'meal'])) {
    return Icons.restaurant_outlined;
  }
  if (has(['repair', 'machine', 'service', 'welding', 'spare'])) {
    return Icons.build_outlined;
  }
  if (has(['diesel', 'fuel', 'petrol', 'oil', 'gas'])) {
    return Icons.local_gas_station_outlined;
  }
  if (has(['electric', 'power', 'light'])) return Icons.bolt_outlined;
  if (has(['transport', 'truck', 'tractor', 'freight', 'delivery'])) {
    return Icons.local_shipping_outlined;
  }
  if (has(['rent', 'house', 'office'])) return Icons.home_work_outlined;
  if (has(['water'])) return Icons.water_drop_outlined;
  if (has(['phone', 'mobile', 'recharge', 'internet'])) {
    return Icons.phone_android_outlined;
  }
  return Icons.receipt_long_outlined;
}

/// The category's icon in a coloured circle; the same category always
/// gets the same colour.
class ExpenseIcon extends StatelessWidget {
  const ExpenseIcon(this.category, {super.key, this.size = 48});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) => ColorAvatar(
    seed: category.toLowerCase(),
    icon: expenseIcon(category),
    size: size,
  );
}
