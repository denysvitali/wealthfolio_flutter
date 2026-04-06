import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';

void main() {
  group('Holding.fromJson', () {
    final validJson = <String, dynamic>{
      'id': 'h-1',
      'account_id': 'acc-1',
      'asset_id': 'AAPL',
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'holding_type': 'EQUITY',
      'quantity': 10.0,
      'market_value': 1800.0,
      'book_value': 1500.0,
      'average_cost': 150.0,
      'currency': 'USD',
      'base_currency': 'USD',
      'market_value_converted': 1800.0,
      'book_value_converted': 1500.0,
      'unrealized_gain': 300.0,
      'unrealized_gain_percent': 20.0,
      'day_change': 15.0,
      'day_change_percent': 0.84,
    };

    test('parses a complete holding', () {
      final holding = Holding.fromJson(validJson);

      expect(holding.id, 'h-1');
      expect(holding.symbol, 'AAPL');
      expect(holding.name, 'Apple Inc.');
      expect(holding.holdingType, 'EQUITY');
      expect(holding.quantity, 10.0);
      expect(holding.marketValue, 1800.0);
      expect(holding.bookValue, 1500.0);
      expect(holding.averageCost, 150.0);
      expect(holding.unrealizedGain, 300.0);
      expect(holding.unrealizedGainPercent, 20.0);
      expect(holding.dayChange, 15.0);
      expect(holding.dayChangePercent, 0.84);
    });

    test('defaults all doubles to 0.0 when fields are absent', () {
      final holding = Holding.fromJson(<String, dynamic>{});
      expect(holding.quantity, 0.0);
      expect(holding.marketValue, 0.0);
      expect(holding.unrealizedGain, 0.0);
      expect(holding.dayChange, 0.0);
    });

    test('handles null input gracefully', () {
      final holding = Holding.fromJson(null);
      expect(holding.id, '');
      expect(holding.symbol, '');
    });
  });
}
