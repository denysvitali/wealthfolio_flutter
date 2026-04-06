import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Holding {
  const Holding({
    required this.id,
    required this.accountId,
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.holdingType,
    required this.quantity,
    required this.marketValue,
    required this.bookValue,
    required this.averageCost,
    required this.currency,
    required this.baseCurrency,
    required this.marketValueConverted,
    required this.bookValueConverted,
    required this.unrealizedGain,
    required this.unrealizedGainPercent,
    required this.dayChange,
    required this.dayChangePercent,
  });

  final String id;
  final String accountId;
  final String assetId;
  final String symbol;
  final String name;

  /// e.g. 'EQUITY', 'ETF', 'CRYPTO', 'CASH', 'ALTERNATIVE'
  final String holdingType;

  final double quantity;
  final double marketValue;
  final double bookValue;
  final double averageCost;
  final String currency;
  final String baseCurrency;
  final double marketValueConverted;
  final double bookValueConverted;
  final double unrealizedGain;
  final double unrealizedGainPercent;
  final double dayChange;
  final double dayChangePercent;

  factory Holding.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Holding(
      id: parseString(map['id']),
      accountId: parseString(map['accountId']),
      assetId: parseString(map['assetId']),
      symbol: parseString(map['symbol']),
      name: parseString(map['name']),
      holdingType: parseString(map['holdingType']),
      quantity: parseDouble(map['quantity']),
      marketValue: parseDouble(map['marketValue']),
      bookValue: parseDouble(map['bookValue']),
      averageCost: parseDouble(map['averageCost']),
      currency: parseString(map['currency']),
      baseCurrency: parseString(map['baseCurrency']),
      marketValueConverted: parseDouble(map['marketValueConverted']),
      bookValueConverted: parseDouble(map['bookValueConverted']),
      unrealizedGain: parseDouble(map['unrealizedGain']),
      unrealizedGainPercent: parseDouble(map['unrealizedGainPercent']),
      dayChange: parseDouble(map['dayChange']),
      dayChangePercent: parseDouble(map['dayChangePercent']),
    );
  }
}
