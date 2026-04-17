import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class IncomeByAsset {
  const IncomeByAsset({
    required this.assetId,
    required this.kind,
    required this.symbol,
    required this.name,
    required this.income,
  });

  final String assetId;
  final String kind;
  final String symbol;
  final String name;
  final double income;

  factory IncomeByAsset.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return IncomeByAsset(
      assetId: parseString(map['assetId']),
      kind: parseString(map['kind']),
      symbol: parseString(map['symbol']),
      name: parseString(map['name']),
      income: parseDouble(map['income']),
    );
  }
}

class IncomeByAccount {
  const IncomeByAccount({
    required this.accountId,
    required this.accountName,
    required this.byMonth,
    required this.total,
  });

  final String accountId;
  final String accountName;
  final Map<String, double> byMonth;
  final double total;

  factory IncomeByAccount.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return IncomeByAccount(
      accountId: parseString(map['accountId']),
      accountName: parseString(map['accountName']),
      byMonth: _decimalMap(map['byMonth']),
      total: parseDouble(map['total']),
    );
  }
}

/// One `IncomeSummary` entry returned by `GET /api/v1/income/summary`. The
/// server returns a list keyed by `period` (`TOTAL`, `YTD`, `LAST_YEAR`).
class IncomeSummary {
  const IncomeSummary({
    required this.period,
    required this.byMonth,
    required this.byType,
    required this.byAsset,
    required this.byCurrency,
    required this.byAccount,
    required this.totalIncome,
    required this.currency,
    required this.monthlyAverage,
    this.yoyGrowth,
  });

  /// Period key — `TOTAL`, `YTD`, or `LAST_YEAR`.
  final String period;

  /// ISO date (YYYY-MM-DD) -> income in base currency.
  final Map<String, double> byMonth;

  /// Activity type (e.g. `DIVIDEND`, `INTEREST`) -> income in base currency.
  final Map<String, double> byType;

  /// Asset ID -> per-asset income breakdown.
  final Map<String, IncomeByAsset> byAsset;

  /// Currency code -> income in that currency (not converted).
  final Map<String, double> byCurrency;

  /// Account ID -> per-account income breakdown.
  final Map<String, IncomeByAccount> byAccount;

  /// Total income in base currency.
  final double totalIncome;

  /// Base currency (e.g. `USD`).
  final String currency;

  /// Average monthly income in base currency.
  final double monthlyAverage;

  /// YoY growth rate, when available.
  final double? yoyGrowth;

  /// Convenience alias for UIs that used to plot per-month totals.
  double get totalDividends => byType['DIVIDEND'] ?? 0;
  double get totalInterest => byType['INTEREST'] ?? 0;

  factory IncomeSummary.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return IncomeSummary(
      period: parseString(map['period']),
      byMonth: _decimalMap(map['byMonth']),
      byType: _decimalMap(map['byType']),
      byAsset: _assetMap(map['byAsset']),
      byCurrency: _decimalMap(map['byCurrency']),
      byAccount: _accountMap(map['byAccount']),
      totalIncome: parseDouble(map['totalIncome']),
      currency: parseString(map['currency']),
      monthlyAverage: parseDouble(map['monthlyAverage']),
      yoyGrowth: map['yoyGrowth'] == null
          ? null
          : parseDouble(map['yoyGrowth']),
    );
  }

  static IncomeSummary empty({String currency = 'USD', String period = 'TOTAL'}) =>
      IncomeSummary(
        period: period,
        byMonth: const <String, double>{},
        byType: const <String, double>{},
        byAsset: const <String, IncomeByAsset>{},
        byCurrency: const <String, double>{},
        byAccount: const <String, IncomeByAccount>{},
        totalIncome: 0,
        currency: currency,
        monthlyAverage: 0,
      );
}

/// Parses the full `Vec<IncomeSummary>` returned by the server into a
/// period-indexed map. Missing periods fall back to an empty summary.
class IncomeSummaryPeriods {
  const IncomeSummaryPeriods({required this.periods});

  final Map<String, IncomeSummary> periods;

  IncomeSummary get total =>
      periods['TOTAL'] ?? IncomeSummary.empty(period: 'TOTAL');
  IncomeSummary get ytd => periods['YTD'] ?? IncomeSummary.empty(period: 'YTD');
  IncomeSummary get lastYear =>
      periods['LAST_YEAR'] ?? IncomeSummary.empty(period: 'LAST_YEAR');

  factory IncomeSummaryPeriods.fromJson(dynamic raw) {
    final items = parseList(raw).map(IncomeSummary.fromJson).toList();
    final map = <String, IncomeSummary>{
      for (final item in items) item.period: item,
    };
    return IncomeSummaryPeriods(periods: map);
  }
}

Map<String, double> _decimalMap(dynamic raw) {
  final map = parseMap(raw);
  return <String, double>{
    for (final entry in map.entries) entry.key: parseDouble(entry.value),
  };
}

Map<String, IncomeByAsset> _assetMap(dynamic raw) {
  final map = parseMap(raw);
  return <String, IncomeByAsset>{
    for (final entry in map.entries)
      entry.key: IncomeByAsset.fromJson(entry.value),
  };
}

Map<String, IncomeByAccount> _accountMap(dynamic raw) {
  final map = parseMap(raw);
  return <String, IncomeByAccount>{
    for (final entry in map.entries)
      entry.key: IncomeByAccount.fromJson(entry.value),
  };
}
