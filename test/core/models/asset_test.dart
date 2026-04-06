import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/asset.dart';

void main() {
  group('Asset.fromJson', () {
    test('parses a complete asset', () {
      final json = <String, dynamic>{
        'id': 'AAPL',
        'isin': 'US0378331005',
        'name': 'Apple Inc.',
        'asset_type': 'EQUITY',
        'symbol': 'AAPL',
        'symbol_mapping': 'AAPL.US',
        'asset_class': 'STOCK',
        'asset_sub_class': 'LARGE_CAP',
        'comment': 'Tech giant',
        'countries': '{"US":1.0}',
        'categories': null,
        'classes': null,
        'attributes': null,
        'currency': 'USD',
        'data_source': 'YAHOO',
        'sectors': '{"Technology":1.0}',
        'url': 'https://finance.yahoo.com/quote/AAPL',
        'quote_mode': 'AUTO',
      };

      final asset = Asset.fromJson(json);
      expect(asset.id, 'AAPL');
      expect(asset.isin, 'US0378331005');
      expect(asset.name, 'Apple Inc.');
      expect(asset.assetType, 'EQUITY');
      expect(asset.symbol, 'AAPL');
      expect(asset.symbolMapping, 'AAPL.US');
      expect(asset.currency, 'USD');
      expect(asset.dataSource, 'YAHOO');
      expect(asset.quoteMode, 'AUTO');
    });

    test('uses AUTO as default quoteMode', () {
      final asset = Asset.fromJson(<String, dynamic>{
        'id': 'BTC',
        'name': 'Bitcoin',
        'asset_type': 'CRYPTO',
        'symbol': 'BTC-USD',
        'currency': 'USD',
        'data_source': 'COINGECKO',
      });

      expect(asset.quoteMode, 'AUTO');
      expect(asset.isin, null);
      expect(asset.assetClass, null);
    });

    test('handles null input', () {
      final asset = Asset.fromJson(null);
      expect(asset.id, '');
      expect(asset.symbol, '');
    });
  });
}
