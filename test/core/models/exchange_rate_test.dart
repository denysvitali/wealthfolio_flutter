import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/exchange_rate.dart';

void main() {
  group('ExchangeRate.fromJson', () {
    test('parses a complete exchange rate', () {
      final json = <String, dynamic>{
        'id': 'er-1',
        'from_currency': 'USD',
        'to_currency': 'EUR',
        'rate': 0.9215,
        'source': 'ECB',
        'created_at': '2024-03-15T00:00:00Z',
        'updated_at': '2024-03-15T00:00:00Z',
      };

      final rate = ExchangeRate.fromJson(json);
      expect(rate.id, 'er-1');
      expect(rate.fromCurrency, 'USD');
      expect(rate.toCurrency, 'EUR');
      expect(rate.rate, 0.9215);
      expect(rate.source, 'ECB');
    });

    test('parses rate from string value', () {
      final json = <String, dynamic>{
        'id': 'er-2',
        'from_currency': 'GBP',
        'to_currency': 'USD',
        'rate': '1.2650',
        'source': 'YAHOO',
        'created_at': '',
        'updated_at': '',
      };

      final rate = ExchangeRate.fromJson(json);
      expect(rate.rate, 1.2650);
    });

    test('handles null input', () {
      final rate = ExchangeRate.fromJson(null);
      expect(rate.id, '');
      expect(rate.rate, 0.0);
    });
  });
}
