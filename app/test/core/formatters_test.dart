import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/utils/formatters.dart';

void main() {
  test('money uses ₹ and Indian grouping', () {
    expect(Fmt.money('48500.00'), '₹48,500');
    expect(Fmt.money('125000.00'), '₹1,25,000');
    expect(Fmt.money('12345678.50', decimals: true), '₹1,23,45,678.50');
    expect(Fmt.money(null), '₹0');
  });

  test('count keeps whole numbers clean and up to 2 decimals', () {
    expect(Fmt.count('12400.00'), '12,400');
    expect(Fmt.count(1250000), '12,50,000');
    expect(Fmt.count('2.50'), '2.5');
  });

  test('business date is shown as is', () {
    expect(Fmt.date('2026-11-08'), '08 Nov 2026');
    expect(Fmt.date(null), '—');
  });

  test('initials', () {
    expect(Fmt.initials('Rahim Traders'), 'RT');
    expect(Fmt.initials('kartik'), 'KA');
    expect(Fmt.initials('  '), '?');
  });
}
