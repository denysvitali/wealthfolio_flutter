import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// Daily per-account valuation snapshot. Matches the server's
/// `DailyAccountValuation` (camelCase).
class DailyAccountValuation {
  const DailyAccountValuation({
    required this.id,
    required this.accountId,
    required this.valuationDate,
    required this.accountCurrency,
    required this.baseCurrency,
    required this.fxRateToBase,
    required this.cashBalance,
    required this.investmentMarketValue,
    required this.totalValue,
    required this.costBasis,
    required this.netContribution,
    required this.calculatedAt,
  });

  final String id;
  final String accountId;

  /// Calendar date of the valuation (YYYY-MM-DD).
  final String valuationDate;

  final String accountCurrency;
  final String baseCurrency;

  /// FX rate used to convert account currency into the base currency.
  final double fxRateToBase;

  /// Cash balance in the account currency.
  final double cashBalance;

  /// Market value of investments in the account currency.
  final double investmentMarketValue;

  /// Total value (cash + investments) in the account currency.
  final double totalValue;

  /// Cost basis of the investments in the account currency.
  final double costBasis;

  /// Net contributions (deposits - withdrawals) in the account currency.
  final double netContribution;

  /// ISO timestamp for when the valuation was calculated.
  final String calculatedAt;

  factory DailyAccountValuation.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return DailyAccountValuation(
      id: parseString(map['id']),
      accountId: parseString(map['accountId']),
      valuationDate: parseString(map['valuationDate']),
      accountCurrency: parseString(map['accountCurrency']),
      baseCurrency: parseString(map['baseCurrency']),
      fxRateToBase: parseDouble(map['fxRateToBase']),
      cashBalance: parseDouble(map['cashBalance']),
      investmentMarketValue: parseDouble(map['investmentMarketValue']),
      totalValue: parseDouble(map['totalValue']),
      costBasis: parseDouble(map['costBasis']),
      netContribution: parseDouble(map['netContribution']),
      calculatedAt: parseString(map['calculatedAt']),
    );
  }
}
