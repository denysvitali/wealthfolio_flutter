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
      accountId: parseString(map['account_id']),
      assetId: parseString(map['asset_id']),
      symbol: parseString(map['symbol']),
      name: parseString(map['name']),
      holdingType: parseString(map['holding_type']),
      quantity: parseDouble(map['quantity']),
      marketValue: parseDouble(map['market_value']),
      bookValue: parseDouble(map['book_value']),
      averageCost: parseDouble(map['average_cost']),
      currency: parseString(map['currency']),
      baseCurrency: parseString(map['base_currency']),
      marketValueConverted: parseDouble(map['market_value_converted']),
      bookValueConverted: parseDouble(map['book_value_converted']),
      unrealizedGain: parseDouble(map['unrealized_gain']),
      unrealizedGainPercent: parseDouble(map['unrealized_gain_percent']),
      dayChange: parseDouble(map['day_change']),
      dayChangePercent: parseDouble(map['day_change_percent']),
    );
  }
}
