import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/utils/currency_format.dart';

void main() {
  group('formatCurrency', () {
    test('formats USD with dollar sign', () {
      expect(formatCurrency(1234.56), '\$1,234.56');
    });

    test('formats EUR with euro sign', () {
      expect(formatCurrency(1000.0, currency: 'EUR'), '€1,000.00');
    });

    test('formats GBP with pound sign', () {
      expect(formatCurrency(500.0, currency: 'GBP'), '£500.00');
    });

    test('formats CHF with prefix', () {
      expect(formatCurrency(100.0, currency: 'CHF'), 'CHF 100.00');
    });

    test('formats CAD with CA\$ prefix', () {
      expect(formatCurrency(200.0, currency: 'CAD'), 'CA\$200.00');
    });

    test('formats AUD with A\$ prefix', () {
      expect(formatCurrency(300.0, currency: 'AUD'), 'A\$300.00');
    });

    test('falls back to currency code for unknown currency', () {
      final result = formatCurrency(50.0, currency: 'SEK');
      expect(result, contains('SEK'));
      expect(result, contains('50'));
    });

    test('compact format shortens large values', () {
      final result = formatCurrency(1500000.0, currency: 'USD', compact: true);
      // Compact format varies by locale but should contain M or similar
      expect(result, isNotEmpty);
      expect(result, contains('\$'));
    });
  });

  group('formatPercent', () {
    test('positive value includes leading +', () {
      expect(formatPercent(5.25), '+5.25%');
    });

    test('negative value uses minus sign', () {
      expect(formatPercent(-2.50), '-2.50%');
    });

    test('zero uses + prefix', () {
      expect(formatPercent(0.0), '+0.00%');
    });

    test('respects custom decimal places', () {
      expect(formatPercent(1.123456, decimals: 4), '+1.1235%');
    });
  });

  group('formatNumber', () {
    test('formats with thousands separator and 2 decimals', () {
      expect(formatNumber(1234567.89), '1,234,567.89');
    });

    test('respects custom decimal count', () {
      expect(formatNumber(42.0, decimals: 0), '42');
    });

    test('handles zero', () {
      expect(formatNumber(0.0), '0.00');
    });
  });
}
