import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/quote.dart';

void main() {
  group('Quote.fromJson', () {
    test('parses a full quote record', () {
      final json = <String, dynamic>{
        'id': 'q-1',
        'created_at': '2024-03-15T16:00:00Z',
        'data_source': 'YAHOO',
        'date': '2024-03-15',
        'symbol': 'AAPL',
        'open': 172.0,
        'high': 180.0,
        'low': 171.5,
        'volume': 1000000.0,
        'close': 178.50,
        'adjclose': 178.50,
      };

      final quote = Quote.fromJson(json);
      expect(quote.id, 'q-1');
      expect(quote.dataSource, 'YAHOO');
      expect(quote.date, '2024-03-15');
      expect(quote.symbol, 'AAPL');
      expect(quote.open, 172.0);
      expect(quote.high, 180.0);
      expect(quote.low, 171.5);
      expect(quote.volume, 1000000.0);
      expect(quote.close, 178.50);
      expect(quote.adjclose, 178.50);
    });

    test('handles null input gracefully', () {
      final quote = Quote.fromJson(null);
      expect(quote.symbol, '');
      expect(quote.close, 0.0);
    });
  });
}
