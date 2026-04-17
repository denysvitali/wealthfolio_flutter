import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// Quote / price observation. Matches the Axum server's `Quote` (camelCase).
class Quote {
  const Quote({
    required this.id,
    required this.assetId,
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.adjclose,
    required this.volume,
    required this.currency,
    required this.dataSource,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String assetId;

  /// ISO 8601 timestamp when this price was observed.
  final String timestamp;

  final double open;
  final double high;
  final double low;
  final double close;
  final double adjclose;
  final double volume;
  final String currency;

  /// e.g. `YAHOO`, `MANUAL`, `COINGECKO`.
  final String dataSource;

  final String createdAt;
  final String? notes;

  /// Backwards-compatible alias for UIs that still plot `quote.date`.
  String get date => timestamp;

  factory Quote.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Quote(
      id: parseString(map['id']),
      assetId: parseString(map['assetId'] ?? map['asset_id']),
      timestamp: parseString(map['timestamp'] ?? map['date']),
      open: parseDouble(map['open']),
      high: parseDouble(map['high']),
      low: parseDouble(map['low']),
      close: parseDouble(map['close']),
      adjclose: parseDouble(map['adjclose']),
      volume: parseDouble(map['volume']),
      currency: parseString(map['currency']),
      dataSource: parseString(map['dataSource'] ?? map['data_source']),
      createdAt: parseString(map['createdAt'] ?? map['created_at']),
      notes: map['notes'] as String?,
    );
  }

  /// Serialises a quote back to the REST shape used by
  /// `PUT /api/v1/market-data/quotes/{symbol}`.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'assetId': assetId,
        'timestamp': timestamp,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'adjclose': adjclose,
        'volume': volume,
        'currency': currency,
        'dataSource': dataSource,
        'createdAt': createdAt,
        if (notes != null) 'notes': notes,
      };
}
