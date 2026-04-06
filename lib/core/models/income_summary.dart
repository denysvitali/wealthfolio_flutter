import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class MonthlyIncome {
  const MonthlyIncome({
    required this.month,
    required this.dividends,
    required this.interest,
  });

  /// ISO month string, e.g. '2024-03'
  final String month;

  final double dividends;
  final double interest;

  factory MonthlyIncome.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return MonthlyIncome(
      month: parseString(map['month']),
      dividends: parseDouble(map['dividends']),
      interest: parseDouble(map['interest']),
    );
  }
}

class IncomeSummary {
  const IncomeSummary({
    required this.currency,
    required this.totalDividends,
    required this.totalInterest,
    required this.byMonth,
  });

  final String currency;
  final double totalDividends;
  final double totalInterest;
  final List<MonthlyIncome> byMonth;

  factory IncomeSummary.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawList = parseList(map['by_month']);
    return IncomeSummary(
      currency: parseString(map['currency']),
      totalDividends: parseDouble(map['total_dividends']),
      totalInterest: parseDouble(map['total_interest']),
      byMonth: rawList.map(MonthlyIncome.fromJson).toList(),
    );
  }
}
