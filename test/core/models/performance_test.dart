import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/performance.dart';

void main() {
  group('PerformanceMetrics.fromJson', () {
    test('parses all fields', () {
      final json = <String, dynamic>{
        'total_value': 50000.0,
        'total_gain_loss': 5000.0,
        'total_gain_loss_percent': 11.11,
        'day_gain_loss': 150.0,
        'day_gain_loss_percent': 0.30,
        'contributions': 45000.0,
        'withdrawals': 0.0,
      };

      final metrics = PerformanceMetrics.fromJson(json);
      expect(metrics.totalValue, 50000.0);
      expect(metrics.totalGainLoss, 5000.0);
      expect(metrics.totalGainLossPercent, 11.11);
      expect(metrics.dayGainLoss, 150.0);
      expect(metrics.dayGainLossPercent, 0.30);
      expect(metrics.contributions, 45000.0);
      expect(metrics.withdrawals, 0.0);
    });

    test('defaults all to 0.0 on null input', () {
      final metrics = PerformanceMetrics.fromJson(null);
      expect(metrics.totalValue, 0.0);
      expect(metrics.contributions, 0.0);
    });
  });

  group('PerformanceHistory.fromJson', () {
    test('parses date and values', () {
      final json = <String, dynamic>{
        'date': '2024-03-31',
        'value': 48000.0,
        'gain_loss': 3000.0,
        'gain_loss_percent': 6.67,
      };

      final history = PerformanceHistory.fromJson(json);
      expect(history.date, '2024-03-31');
      expect(history.value, 48000.0);
      expect(history.gainLoss, 3000.0);
      expect(history.gainLossPercent, 6.67);
    });

    test('handles null input', () {
      final history = PerformanceHistory.fromJson(null);
      expect(history.date, '');
      expect(history.value, 0.0);
    });
  });
}
