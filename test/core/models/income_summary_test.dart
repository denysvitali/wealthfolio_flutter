import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/income_summary.dart';

void main() {
  group('IncomeSummary.fromJson', () {
    test('parses the server payload (camelCase)', () {
      final json = <String, dynamic>{
        'period': 'TOTAL',
        'byMonth': <String, dynamic>{
          '2024-01-01': 250.0,
          '2024-02-01': 270.5,
        },
        'byType': <String, dynamic>{
          'DIVIDEND': 500.0,
          'INTEREST': 25.0,
        },
        'byAsset': <String, dynamic>{
          'asset-1': <String, dynamic>{
            'assetId': 'asset-1',
            'kind': 'EQUITY',
            'symbol': 'AAPL',
            'name': 'Apple Inc.',
            'income': 300.0,
          },
        },
        'byCurrency': <String, dynamic>{'USD': 520.5},
        'byAccount': <String, dynamic>{
          'acct-1': <String, dynamic>{
            'accountId': 'acct-1',
            'accountName': 'Main',
            'byMonth': <String, dynamic>{'2024-01-01': 100.0},
            'total': 100.0,
          },
        },
        'totalIncome': 520.5,
        'currency': 'USD',
        'monthlyAverage': 43.4,
        'yoyGrowth': 0.1,
      };

      final summary = IncomeSummary.fromJson(json);
      expect(summary.period, 'TOTAL');
      expect(summary.currency, 'USD');
      expect(summary.totalIncome, 520.5);
      expect(summary.monthlyAverage, 43.4);
      expect(summary.yoyGrowth, 0.1);
      expect(summary.byMonth['2024-01-01'], 250.0);
      expect(summary.byType['DIVIDEND'], 500.0);
      expect(summary.byAsset['asset-1']?.symbol, 'AAPL');
      expect(summary.byCurrency['USD'], 520.5);
      expect(summary.byAccount['acct-1']?.total, 100.0);
      expect(summary.totalDividends, 500.0);
      expect(summary.totalInterest, 25.0);
    });

    test('handles null input', () {
      final summary = IncomeSummary.fromJson(null);
      expect(summary.period, '');
      expect(summary.currency, '');
      expect(summary.byMonth, isEmpty);
    });
  });

  group('IncomeSummaryPeriods.fromJson', () {
    test('indexes server response array by period', () {
      final raw = <Map<String, dynamic>>[
        {
          'period': 'TOTAL',
          'byMonth': <String, dynamic>{},
          'byType': <String, dynamic>{},
          'byAsset': <String, dynamic>{},
          'byCurrency': <String, dynamic>{},
          'byAccount': <String, dynamic>{},
          'totalIncome': 1000,
          'currency': 'USD',
          'monthlyAverage': 83.3,
        },
        {
          'period': 'YTD',
          'byMonth': <String, dynamic>{},
          'byType': <String, dynamic>{},
          'byAsset': <String, dynamic>{},
          'byCurrency': <String, dynamic>{},
          'byAccount': <String, dynamic>{},
          'totalIncome': 100,
          'currency': 'USD',
          'monthlyAverage': 50,
        },
      ];

      final periods = IncomeSummaryPeriods.fromJson(raw);
      expect(periods.total.totalIncome, 1000);
      expect(periods.ytd.totalIncome, 100);
      expect(periods.lastYear.totalIncome, 0); // empty fallback
    });

    test('handles empty server payload', () {
      final periods = IncomeSummaryPeriods.fromJson(null);
      expect(periods.total.totalIncome, 0);
      expect(periods.ytd.totalIncome, 0);
      expect(periods.lastYear.totalIncome, 0);
    });
  });
}
