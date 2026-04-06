import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/portfolio_allocation.dart';

void main() {
  group('PortfolioAllocation.fromJson', () {
    test('parses a complete allocation', () {
      final json = <String, dynamic>{
        'name': 'Technology',
        'value': 25000.0,
        'percentage': 45.5,
        'color': '#4e9af1',
      };

      final alloc = PortfolioAllocation.fromJson(json);
      expect(alloc.name, 'Technology');
      expect(alloc.value, 25000.0);
      expect(alloc.percentage, 45.5);
      expect(alloc.color, '#4e9af1');
    });

    test('color is null when absent', () {
      final alloc = PortfolioAllocation.fromJson(<String, dynamic>{
        'name': 'Healthcare',
        'value': 10000.0,
        'percentage': 18.2,
      });
      expect(alloc.color, null);
    });

    test('handles null input', () {
      final alloc = PortfolioAllocation.fromJson(null);
      expect(alloc.name, '');
      expect(alloc.value, 0.0);
      expect(alloc.percentage, 0.0);
    });
  });

  group('AllocationHoldings.fromJson', () {
    test('parses holdings list', () {
      final json = <String, dynamic>{
        'holdings': [
          <String, dynamic>{
            'id': 'h-1',
            'account_id': 'acc-1',
            'asset_id': 'AAPL',
            'symbol': 'AAPL',
            'name': 'Apple Inc.',
            'holding_type': 'EQUITY',
            'quantity': 5.0,
            'market_value': 900.0,
            'book_value': 800.0,
            'average_cost': 160.0,
            'currency': 'USD',
            'base_currency': 'USD',
            'market_value_converted': 900.0,
            'book_value_converted': 800.0,
            'unrealized_gain': 100.0,
            'unrealized_gain_percent': 12.5,
            'day_change': 10.0,
            'day_change_percent': 1.12,
          },
        ],
      };

      final ah = AllocationHoldings.fromJson(json);
      expect(ah.holdings.length, 1);
      expect(ah.holdings.first.symbol, 'AAPL');
    });

    test('returns empty list for null input', () {
      final ah = AllocationHoldings.fromJson(null);
      expect(ah.holdings, isEmpty);
    });
  });
}
