import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/exchange_rate.dart';

void main() {
  group('ExchangeRate.fromJson', () {
    test('parses a complete exchange rate (camelCase)', () {
      final json = <String, dynamic>{
        'id': 'er-1',
        'fromCurrency': 'USD',
        'toCurrency': 'EUR',
        'rate': 0.9215,
        'source': 'ECB',
        'timestamp': '2024-03-15T00:00:00Z',
      };

      final rate = ExchangeRate.fromJson(json);
      expect(rate.id, 'er-1');
      expect(rate.fromCurrency, 'USD');
      expect(rate.toCurrency, 'EUR');
      expect(rate.rate, 0.9215);
      expect(rate.source, 'ECB');
      expect(rate.timestamp, '2024-03-15T00:00:00Z');
    });

    test('accepts legacy snake_case field names', () {
      final json = <String, dynamic>{
        'id': 'er-2',
        'from_currency': 'GBP',
        'to_currency': 'USD',
        'rate': '1.2650',
        'source': 'YAHOO',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final rate = ExchangeRate.fromJson(json);
      expect(rate.fromCurrency, 'GBP');
      expect(rate.toCurrency, 'USD');
      expect(rate.rate, 1.2650);
      expect(rate.timestamp, '2024-01-02T00:00:00Z');
    });

    test('handles null input', () {
      final rate = ExchangeRate.fromJson(null);
      expect(rate.id, '');
      expect(rate.rate, 0.0);
    });
  });
}
