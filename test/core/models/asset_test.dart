import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/asset.dart';

void main() {
  group('Asset.fromJson', () {
    test('parses the server camelCase payload', () {
      final json = <String, dynamic>{
        'id': 'SEC:AAPL:XNAS',
        'kind': 'INVESTMENT',
        'name': 'Apple Inc.',
        'displayCode': 'AAPL',
        'notes': 'Tech giant',
        'metadata': <String, dynamic>{'sectors': <String, dynamic>{'Technology': 1.0}},
        'isActive': true,
        'quoteMode': 'MARKET',
        'quoteCcy': 'USD',
        'instrumentType': 'EQUITY',
        'instrumentSymbol': 'AAPL',
        'instrumentExchangeMic': 'XNAS',
        'instrumentKey': 'SEC:AAPL:XNAS',
        'exchangeName': 'NASDAQ',
        'createdAt': '2024-01-01T00:00:00',
        'updatedAt': '2024-04-01T00:00:00',
      };

      final asset = Asset.fromJson(json);
      expect(asset.id, 'SEC:AAPL:XNAS');
      expect(asset.kind, 'INVESTMENT');
      expect(asset.name, 'Apple Inc.');
      expect(asset.displayCode, 'AAPL');
      expect(asset.quoteMode, 'MARKET');
      expect(asset.quoteCcy, 'USD');
      expect(asset.currency, 'USD');
      expect(asset.instrumentType, 'EQUITY');
      expect(asset.instrumentSymbol, 'AAPL');
      expect(asset.instrumentExchangeMic, 'XNAS');
      expect(asset.exchangeName, 'NASDAQ');
      expect(asset.isActive, isTrue);
      expect(asset.symbol, 'AAPL');
    });

    test('falls back to sensible defaults for minimal payloads', () {
      final asset = Asset.fromJson(<String, dynamic>{
        'id': 'BTC',
        'kind': 'INVESTMENT',
        'quoteMode': 'MARKET',
        'quoteCcy': 'USD',
      });

      expect(asset.id, 'BTC');
      expect(asset.isActive, isTrue); // defaults to true per server schema
      expect(asset.name, isNull);
      expect(asset.instrumentSymbol, isNull);
      expect(asset.symbol, 'BTC'); // fallback to the id tail
    });

    test('handles null input', () {
      final asset = Asset.fromJson(null);
      expect(asset.id, '');
      expect(asset.kind, 'OTHER');
      expect(asset.symbol, '');
    });
  });
}
