import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class PerformanceMetrics {
  const PerformanceMetrics({
    required this.totalValue,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.dayGainLoss,
    required this.dayGainLossPercent,
    required this.contributions,
    required this.withdrawals,
  });

  final double totalValue;
  final double totalGainLoss;
  final double totalGainLossPercent;
  final double dayGainLoss;
  final double dayGainLossPercent;
  final double contributions;
  final double withdrawals;

  factory PerformanceMetrics.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return PerformanceMetrics(
      totalValue: parseDouble(map['total_value']),
      totalGainLoss: parseDouble(map['total_gain_loss']),
      totalGainLossPercent: parseDouble(map['total_gain_loss_percent']),
      dayGainLoss: parseDouble(map['day_gain_loss']),
      dayGainLossPercent: parseDouble(map['day_gain_loss_percent']),
      contributions: parseDouble(map['contributions']),
      withdrawals: parseDouble(map['withdrawals']),
    );
  }
}

class PerformanceHistory {
  const PerformanceHistory({
    required this.date,
    required this.value,
    required this.gainLoss,
    required this.gainLossPercent,
  });

  final String date;
  final double value;
  final double gainLoss;
  final double gainLossPercent;

  factory PerformanceHistory.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return PerformanceHistory(
      date: parseString(map['date']),
      value: parseDouble(map['value']),
      gainLoss: parseDouble(map['gain_loss']),
      gainLossPercent: parseDouble(map['gain_loss_percent']),
    );
  }
}
