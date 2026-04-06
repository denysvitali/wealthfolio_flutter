import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/net_worth.dart';

void main() {
  group('NetWorthResponse.fromJson', () {
    test('parses all fields', () {
      final json = <String, dynamic>{
        'total': 150000.0,
        'assets_total': 160000.0,
        'liabilities_total': 10000.0,
        'investments_total': 120000.0,
        'cash_total': 30000.0,
        'alternatives_total': 10000.0,
      };

      final nw = NetWorthResponse.fromJson(json);
      expect(nw.total, 150000.0);
      expect(nw.assetsTotal, 160000.0);
      expect(nw.liabilitiesTotal, 10000.0);
      expect(nw.investmentsTotal, 120000.0);
      expect(nw.cashTotal, 30000.0);
      expect(nw.alternativesTotal, 10000.0);
    });

    test('defaults to 0.0 for null input', () {
      final nw = NetWorthResponse.fromJson(null);
      expect(nw.total, 0.0);
      expect(nw.assetsTotal, 0.0);
    });
  });

  group('NetWorthHistoryPoint.fromJson', () {
    test('parses a history point', () {
      final json = <String, dynamic>{
        'date': '2024-01-31',
        'total': 140000.0,
        'investments': 110000.0,
        'cash': 25000.0,
        'alternatives': 8000.0,
        'liabilities': 3000.0,
      };

      final point = NetWorthHistoryPoint.fromJson(json);
      expect(point.date, '2024-01-31');
      expect(point.total, 140000.0);
      expect(point.investments, 110000.0);
      expect(point.cash, 25000.0);
      expect(point.alternatives, 8000.0);
      expect(point.liabilities, 3000.0);
    });

    test('defaults to 0.0 on empty input', () {
      final point = NetWorthHistoryPoint.fromJson(<String, dynamic>{});
      expect(point.total, 0.0);
      expect(point.date, '');
    });
  });
}
