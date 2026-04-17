import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/net_worth.dart';

void main() {
  group('NetWorthResponse.fromJson', () {
    test('parses the balance-sheet payload returned by the server', () {
      final json = <String, dynamic>{
        'date': '2026-01-31',
        'assets': <String, dynamic>{
          'total': 160000.0,
          'breakdown': <Map<String, dynamic>>[
            {
              'category': 'investments',
              'name': 'Investments',
              'value': 120000.0,
            },
            {'category': 'cash', 'name': 'Cash', 'value': 30000.0},
            {
              'category': 'properties',
              'name': 'Properties',
              'value': 7000.0,
            },
            {
              'category': 'vehicles',
              'name': 'Vehicles',
              'value': 3000.0,
            },
          ],
        },
        'liabilities': <String, dynamic>{
          'total': 10000.0,
          'breakdown': <Map<String, dynamic>>[
            {
              'category': 'liability',
              'name': 'Mortgage',
              'value': 10000.0,
              'assetId': 'liab-1',
            },
          ],
        },
        'netWorth': 150000.0,
        'currency': 'USD',
        'oldestValuationDate': '2024-01-01',
        'staleAssets': <Map<String, dynamic>>[
          {
            'assetId': 'asset-123',
            'name': 'Old Holding',
            'valuationDate': '2025-01-01',
            'daysStale': 365,
          },
        ],
      };

      final nw = NetWorthResponse.fromJson(json);
      expect(nw.date, '2026-01-31');
      expect(nw.netWorth, 150000.0);
      expect(nw.total, 150000.0); // alias of netWorth
      expect(nw.currency, 'USD');
      expect(nw.assetsTotal, 160000.0);
      expect(nw.liabilitiesTotal, 10000.0);
      expect(nw.investmentsTotal, 120000.0);
      expect(nw.cashTotal, 30000.0);
      expect(nw.alternativesTotal, 10000.0);
      expect(nw.assets.breakdown.length, 4);
      expect(nw.liabilities.breakdown.first.assetId, 'liab-1');
      expect(nw.oldestValuationDate, '2024-01-01');
      expect(nw.staleAssets.first.daysStale, 365);
    });

    test('defaults to zero totals on null input', () {
      final nw = NetWorthResponse.fromJson(null);
      expect(nw.total, 0.0);
      expect(nw.assetsTotal, 0.0);
      expect(nw.liabilitiesTotal, 0.0);
      expect(nw.investmentsTotal, 0.0);
      expect(nw.cashTotal, 0.0);
      expect(nw.alternativesTotal, 0.0);
      expect(nw.staleAssets, isEmpty);
    });
  });

  group('NetWorthHistoryPoint.fromJson', () {
    test('parses the camelCase history point', () {
      final json = <String, dynamic>{
        'date': '2024-01-31',
        'portfolioValue': 135000.0,
        'alternativeAssetsValue': 8000.0,
        'totalLiabilities': 3000.0,
        'totalAssets': 143000.0,
        'netWorth': 140000.0,
        'netContribution': 100000.0,
        'currency': 'USD',
      };

      final point = NetWorthHistoryPoint.fromJson(json);
      expect(point.date, '2024-01-31');
      expect(point.portfolioValue, 135000.0);
      expect(point.alternativeAssetsValue, 8000.0);
      expect(point.totalLiabilities, 3000.0);
      expect(point.totalAssets, 143000.0);
      expect(point.netWorth, 140000.0);
      expect(point.total, 140000.0); // alias of netWorth
      expect(point.netContribution, 100000.0);
      expect(point.currency, 'USD');
    });

    test('defaults to 0.0 on empty input', () {
      final point = NetWorthHistoryPoint.fromJson(<String, dynamic>{});
      expect(point.total, 0.0);
      expect(point.date, '');
    });
  });
}
