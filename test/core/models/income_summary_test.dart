import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/income_summary.dart';

void main() {
  group('MonthlyIncome.fromJson', () {
    test('parses month and income fields', () {
      final json = <String, dynamic>{
        'month': '2024-03',
        'dividends': 120.50,
        'interest': 5.25,
      };

      final income = MonthlyIncome.fromJson(json);
      expect(income.month, '2024-03');
      expect(income.dividends, 120.50);
      expect(income.interest, 5.25);
    });

    test('defaults to empty/zero on null', () {
      final income = MonthlyIncome.fromJson(null);
      expect(income.month, '');
      expect(income.dividends, 0.0);
      expect(income.interest, 0.0);
    });
  });

  group('IncomeSummary.fromJson', () {
    test('parses currency, totals, and monthly list', () {
      final json = <String, dynamic>{
        'currency': 'USD',
        'total_dividends': 500.0,
        'total_interest': 25.0,
        'by_month': [
          <String, dynamic>{
            'month': '2024-01',
            'dividends': 250.0,
            'interest': 12.5,
          },
          <String, dynamic>{
            'month': '2024-02',
            'dividends': 250.0,
            'interest': 12.5,
          },
        ],
      };

      final summary = IncomeSummary.fromJson(json);
      expect(summary.currency, 'USD');
      expect(summary.totalDividends, 500.0);
      expect(summary.totalInterest, 25.0);
      expect(summary.byMonth.length, 2);
      expect(summary.byMonth.first.month, '2024-01');
      expect(summary.byMonth.last.month, '2024-02');
    });

    test('returns empty list when by_month is absent', () {
      final summary = IncomeSummary.fromJson(<String, dynamic>{
        'currency': 'EUR',
      });
      expect(summary.byMonth, isEmpty);
      expect(summary.currency, 'EUR');
    });

    test('handles null input', () {
      final summary = IncomeSummary.fromJson(null);
      expect(summary.currency, '');
      expect(summary.byMonth, isEmpty);
    });
  });
}
