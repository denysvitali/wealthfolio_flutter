import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Quote {
  const Quote({
    required this.id,
    required this.createdAt,
    required this.dataSource,
    required this.date,
    required this.symbol,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.close,
    required this.adjclose,
  });

  final String id;
  final String createdAt;

  /// e.g. 'YAHOO', 'MANUAL', 'COINGECKO'
  final String dataSource;

  final String date;
  final String symbol;
  final double open;
  final double high;
  final double low;
  final double volume;
  final double close;
  final double adjclose;

  factory Quote.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Quote(
      id: parseString(map['id']),
      createdAt: parseString(map['created_at']),
      dataSource: parseString(map['data_source']),
      date: parseString(map['date']),
      symbol: parseString(map['symbol']),
      open: parseDouble(map['open']),
      high: parseDouble(map['high']),
      low: parseDouble(map['low']),
      volume: parseDouble(map['volume']),
      close: parseDouble(map['close']),
      adjclose: parseDouble(map['adjclose']),
    );
  }
}
