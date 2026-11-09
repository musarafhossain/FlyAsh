import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/dates.dart';
import '../utils/formatters.dart';

/// A business-date input ("YYYY-MM-DD") that opens a date picker limited
/// to [first]…[last] (e.g. no future dates).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
    this.icon = Icons.event,
    this.errorText,
  });

  final String label;
  final String value;
  final String first;
  final String last;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String? errorText;

  static DateTime _local(String ymd) {
    final d = Ymd.parse(ymd);
    return DateTime(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: () async {
          final firstDay = _local(first);
          final lastDay = _local(last);
          var initial = _local(value);
          if (initial.isBefore(firstDay)) initial = firstDay;
          if (initial.isAfter(lastDay)) initial = lastDay;
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: firstDay,
            lastDate: lastDay,
          );
          if (picked != null) {
            onChanged(
              Ymd.format(DateTime.utc(picked.year, picked.month, picked.day)),
            );
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            errorText: errorText,
          ),
          child: Text(Fmt.date(value)),
        ),
      ),
    );
  }
}
