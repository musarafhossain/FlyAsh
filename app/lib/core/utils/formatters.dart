import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Display formatters. The API sends money as strings ("48500.00");
/// they are parsed with Decimal (never double) and shown in Indian grouping.
abstract final class Fmt {
  static final _money0 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _money2 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _count = NumberFormat.decimalPattern('en_IN');
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

  /// "48500.00" → "₹48,500" (lists) · decimals: true → "₹48,500.00" (receipts)
  static String money(String? value, {bool decimals = false}) {
    final amount = Decimal.tryParse(value ?? '') ?? Decimal.zero;
    final asNum = amount.toDouble(); // display only
    return (decimals ? _money2 : _money0).format(asNum);
  }

  /// 12400 or "12400.00" → "12,400" (quantities, counts). Keeps up to 2 decimals.
  static String count(Object? value) {
    final d = Decimal.tryParse(value?.toString() ?? '') ?? Decimal.zero;
    final isWhole = d == d.truncate();
    return isWhole
        ? _count.format(d.toBigInt().toInt())
        : NumberFormat('#,##,##0.##', 'en_IN').format(d.toDouble());
  }

  /// Business date "2026-11-08" → "08 Nov 2026" (never timezone-converted).
  static String date(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '—';
    final p = ymd.split('-');
    if (p.length != 3) return ymd;
    return '${p[2].padLeft(2, '0')} ${_months[int.parse(p[1]) - 1]} ${p[0]}';
  }

  /// Initials for avatars: "Rahim Traders" → "RT", "kartik" → "KA".
  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words.first[0] + words[1][0]).toUpperCase();
  }
}
