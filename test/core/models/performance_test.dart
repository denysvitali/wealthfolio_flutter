import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/performance.dart';

void main() {
  group('PerformanceMetrics.fromJson', () {
    test('parses the server camelCase payload', () {
      final json = <String, dynamic>{
        'id': 'portfolio',
        'returns': [
          {'date': '2024-01-01', 'value': 0.0},
          {'date': '2024-12-31', 'value': 0.12},
        ],
        'periodStartDate': '2024-01-01',
        'periodEndDate': '2024-12-31',
        'currency': 'USD',
        'periodGain': 4500.0,
        'periodReturn': 0.10,
        'cumulativeTwr': 0.11,
        'gainLossAmount': 4500.0,
        'annualizedTwr': 0.11,
        'simpleReturn': 0.10,
        'annualizedSimpleReturn': 0.10,
        'cumulativeMwr': 0.105,
        'annualizedMwr': 0.105,
        'volatility': 0.12,
        'maxDrawdown': 0.08,
        'isHoldingsMode': false,
      };

      final metrics = PerformanceMetrics.fromJson(json);
      expect(metrics.id, 'portfolio');
      expect(metrics.returns.length, 2);
      expect(metrics.returns.first.date, '2024-01-01');
      expect(metrics.returns.first.value, 0.0);
      expect(metrics.periodStartDate, '2024-01-01');
      expect(metrics.periodEndDate, '2024-12-31');
      expect(metrics.currency, 'USD');
      expect(metrics.periodGain, 4500.0);
      expect(metrics.periodReturn, 0.10);
      expect(metrics.cumulativeTwr, 0.11);
      expect(metrics.annualizedTwr, 0.11);
      expect(metrics.simpleReturn, 0.10);
      expect(metrics.cumulativeMwr, 0.105);
      expect(metrics.volatility, 0.12);
      expect(metrics.maxDrawdown, 0.08);
      expect(metrics.isHoldingsMode, isFalse);
    });

    test('keeps optional TWR/MWR fields null when absent', () {
      final json = <String, dynamic>{
        'id': 'portfolio',
        'returns': <dynamic>[],
        'currency': 'USD',
        'periodGain': 0,
        'simpleReturn': 0,
        'annualizedSimpleReturn': 0,
        'volatility': 0,
        'maxDrawdown': 0,
        'isHoldingsMode': true,
      };

      final metrics = PerformanceMetrics.fromJson(json);
      expect(metrics.periodReturn, isNull);
      expect(metrics.cumulativeTwr, isNull);
      expect(metrics.annualizedTwr, isNull);
      expect(metrics.cumulativeMwr, isNull);
      expect(metrics.annualizedMwr, isNull);
      expect(metrics.isHoldingsMode, isTrue);
    });

    test('handles null input', () {
      final metrics = PerformanceMetrics.fromJson(null);
      expect(metrics.id, '');
      expect(metrics.returns, isEmpty);
      expect(metrics.currency, '');
      expect(metrics.periodGain, 0.0);
    });
  });

  group('PerformanceHistory.fromJson', () {
    test('parses date and value', () {
      final json = <String, dynamic>{
        'date': '2024-03-31',
        'value': 48000.0,
      };

      final history = PerformanceHistory.fromJson(json);
      expect(history.date, '2024-03-31');
      expect(history.value, 48000.0);
    });

    test('handles null input', () {
      final history = PerformanceHistory.fromJson(null);
      expect(history.date, '');
      expect(history.value, 0.0);
    });
  });
}
