import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class NetWorthResponse {
  const NetWorthResponse({
    required this.total,
    required this.assetsTotal,
    required this.liabilitiesTotal,
    required this.investmentsTotal,
    required this.cashTotal,
    required this.alternativesTotal,
  });

  final double total;
  final double assetsTotal;
  final double liabilitiesTotal;
  final double investmentsTotal;
  final double cashTotal;
  final double alternativesTotal;

  factory NetWorthResponse.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return NetWorthResponse(
      total: parseDouble(map['total']),
      assetsTotal: parseDouble(map['assets_total']),
      liabilitiesTotal: parseDouble(map['liabilities_total']),
      investmentsTotal: parseDouble(map['investments_total']),
      cashTotal: parseDouble(map['cash_total']),
      alternativesTotal: parseDouble(map['alternatives_total']),
    );
  }
}

class NetWorthHistoryPoint {
  const NetWorthHistoryPoint({
    required this.date,
    required this.total,
    required this.investments,
    required this.cash,
    required this.alternatives,
    required this.liabilities,
  });

  final String date;
  final double total;
  final double investments;
  final double cash;
  final double alternatives;
  final double liabilities;

  factory NetWorthHistoryPoint.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return NetWorthHistoryPoint(
      date: parseString(map['date']),
      total: parseDouble(map['total']),
      investments: parseDouble(map['investments']),
      cash: parseDouble(map['cash']),
      alternatives: parseDouble(map['alternatives']),
      liabilities: parseDouble(map['liabilities']),
    );
  }
}
