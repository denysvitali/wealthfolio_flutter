import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class ExchangeRate {
  const ExchangeRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.source,
    required this.timestamp,
  });

  final String id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;

  /// e.g. 'YAHOO', 'MANUAL', 'ECB'
  final String source;

  /// ISO 8601 timestamp of the last observation.
  final String timestamp;

  factory ExchangeRate.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return ExchangeRate(
      id: parseString(map['id']),
      fromCurrency: parseString(
        map['fromCurrency'] ?? map['from_currency'],
      ),
      toCurrency: parseString(map['toCurrency'] ?? map['to_currency']),
      rate: parseDouble(map['rate']),
      source: parseString(map['source']),
      timestamp: parseString(
        map['timestamp'] ?? map['updatedAt'] ?? map['updated_at'],
      ),
    );
  }
}
