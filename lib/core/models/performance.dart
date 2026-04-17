import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// Performance metrics returned by `POST /api/v1/performance/history` and
/// `POST /api/v1/performance/summary`. Shape mirrors the Axum server's
/// `PerformanceMetrics` struct (camelCase JSON).
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.id,
    required this.returns,
    this.periodStartDate,
    this.periodEndDate,
    required this.currency,
    required this.periodGain,
    this.periodReturn,
    this.cumulativeTwr,
    this.gainLossAmount,
    this.annualizedTwr,
    required this.simpleReturn,
    required this.annualizedSimpleReturn,
    this.cumulativeMwr,
    this.annualizedMwr,
    required this.volatility,
    required this.maxDrawdown,
    required this.isHoldingsMode,
  });

  final String id;
  final List<PerformanceHistory> returns;
  final String? periodStartDate;
  final String? periodEndDate;
  final String currency;

  /// Period gain in base currency (change in unrealized P&L for HOLDINGS mode).
  final double periodGain;

  /// Period return percentage. `null` when the period return cannot be
  /// computed (e.g. start_value <= 0).
  final double? periodReturn;

  /// Time-weighted return. `null` for HOLDINGS mode.
  final double? cumulativeTwr;

  /// Legacy gain/loss amount field retained for backward compatibility.
  final double? gainLossAmount;

  /// Annualized TWR. `null` for HOLDINGS mode.
  final double? annualizedTwr;

  final double simpleReturn;
  final double annualizedSimpleReturn;

  /// Money-weighted return. `null` for HOLDINGS mode.
  final double? cumulativeMwr;

  /// Annualized MWR. `null` for HOLDINGS mode.
  final double? annualizedMwr;

  final double volatility;
  final double maxDrawdown;
  final bool isHoldingsMode;

  factory PerformanceMetrics.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawReturns = parseList(map['returns']);
    return PerformanceMetrics(
      id: parseString(map['id']),
      returns: rawReturns.map(PerformanceHistory.fromJson).toList(),
      periodStartDate: map['periodStartDate'] as String?,
      periodEndDate: map['periodEndDate'] as String?,
      currency: parseString(map['currency']),
      periodGain: parseDouble(map['periodGain']),
      periodReturn: _nullableDouble(map['periodReturn']),
      cumulativeTwr: _nullableDouble(map['cumulativeTwr']),
      gainLossAmount: _nullableDouble(map['gainLossAmount']),
      annualizedTwr: _nullableDouble(map['annualizedTwr']),
      simpleReturn: parseDouble(map['simpleReturn']),
      annualizedSimpleReturn: parseDouble(map['annualizedSimpleReturn']),
      cumulativeMwr: _nullableDouble(map['cumulativeMwr']),
      annualizedMwr: _nullableDouble(map['annualizedMwr']),
      volatility: parseDouble(map['volatility']),
      maxDrawdown: parseDouble(map['maxDrawdown']),
      isHoldingsMode: parseBool(map['isHoldingsMode']),
    );
  }
}

/// A single `ReturnData` point inside `PerformanceMetrics.returns`.
class PerformanceHistory {
  const PerformanceHistory({required this.date, required this.value});

  final String date;
  final double value;

  factory PerformanceHistory.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return PerformanceHistory(
      date: parseString(map['date']),
      value: parseDouble(map['value']),
    );
  }
}

double? _nullableDouble(dynamic raw) {
  if (raw == null) return null;
  return parseDouble(raw);
}
