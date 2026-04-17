import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/quote.dart';

void main() {
  group('Quote.fromJson', () {
    test('parses the server camelCase payload', () {
      final json = <String, dynamic>{
        'id': 'q-1',
        'assetId': 'SEC:AAPL:XNAS',
        'timestamp': '2024-03-15T16:00:00Z',
        'open': 172.0,
        'high': 180.0,
        'low': 171.5,
        'close': 178.50,
        'adjclose': 178.50,
        'volume': 1000000.0,
        'currency': 'USD',
        'dataSource': 'YAHOO',
        'createdAt': '2024-03-15T20:00:00Z',
        'notes': 'closing quote',
      };

      final quote = Quote.fromJson(json);
      expect(quote.id, 'q-1');
      expect(quote.assetId, 'SEC:AAPL:XNAS');
      expect(quote.timestamp, '2024-03-15T16:00:00Z');
      expect(quote.date, '2024-03-15T16:00:00Z'); // alias
      expect(quote.open, 172.0);
      expect(quote.close, 178.50);
      expect(quote.adjclose, 178.50);
      expect(quote.volume, 1000000.0);
      expect(quote.currency, 'USD');
      expect(quote.dataSource, 'YAHOO');
      expect(quote.notes, 'closing quote');
    });

    test('accepts legacy snake_case fields', () {
      final quote = Quote.fromJson(<String, dynamic>{
        'id': 'q-legacy',
        'asset_id': 'BTC',
        'date': '2024-01-01',
        'open': 40000,
        'high': 42000,
        'low': 39500,
        'close': 41500,
        'adjclose': 41500,
        'volume': 0,
        'currency': 'USD',
        'data_source': 'COINGECKO',
        'created_at': '2024-01-01T23:59:59Z',
      });
      expect(quote.assetId, 'BTC');
      expect(quote.timestamp, '2024-01-01');
      expect(quote.dataSource, 'COINGECKO');
    });

    test('handles null input gracefully', () {
      final quote = Quote.fromJson(null);
      expect(quote.assetId, '');
      expect(quote.close, 0.0);
      expect(quote.notes, isNull);
    });
  });
}
