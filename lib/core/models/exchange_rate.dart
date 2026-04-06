import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class ExchangeRate {
  const ExchangeRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;

  /// e.g. 'YAHOO', 'MANUAL', 'ECB'
  final String source;

  final String createdAt;
  final String updatedAt;

  factory ExchangeRate.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return ExchangeRate(
      id: parseString(map['id']),
      fromCurrency: parseString(map['from_currency']),
      toCurrency: parseString(map['to_currency']),
      rate: parseDouble(map['rate']),
      source: parseString(map['source']),
      createdAt: parseString(map['created_at']),
      updatedAt: parseString(map['updated_at']),
    );
  }
}
