import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// Domain model for an asset. Matches the Axum server's `Asset` (camelCase).
///
/// Identity is opaque (UUID). Classification (`kind`) is mutable. Market
/// instrument identity lives in the `instrument*` fields (null for non-market
/// assets such as cash, properties, or liabilities).
class Asset {
  const Asset({
    required this.id,
    required this.kind,
    this.name,
    this.displayCode,
    this.notes,
    this.metadata,
    required this.isActive,
    required this.quoteMode,
    required this.quoteCcy,
    this.instrumentType,
    this.instrumentSymbol,
    this.instrumentExchangeMic,
    this.instrumentKey,
    this.providerConfig,
    this.exchangeName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Asset kind: `INVESTMENT`, `PROPERTY`, `VEHICLE`, `COLLECTIBLE`,
  /// `PRECIOUS_METAL`, `PRIVATE_EQUITY`, `LIABILITY`, `OTHER`, `FX`.
  final String kind;

  final String? name;

  /// User-visible ticker/label.
  final String? displayCode;

  final String? notes;

  /// Arbitrary JSON metadata payload (as a map when present).
  final Map<String, dynamic>? metadata;

  final bool isActive;

  /// Quote mode: `MARKET`, `MANUAL`, or `NONE`.
  final String quoteMode;

  /// Currency prices/valuations are quoted in.
  final String quoteCcy;

  /// Instrument type for market assets: `EQUITY`, `CRYPTO`, `FX`, `OPTION`,
  /// `METAL`, `BOND`. Null for non-market assets.
  final String? instrumentType;

  /// Canonical instrument symbol (e.g. `AAPL`, `BTC`, `EUR`).
  final String? instrumentSymbol;

  /// ISO 10383 MIC (`XNAS`, `XTSE`, …).
  final String? instrumentExchangeMic;

  /// Computed canonical key (DB-generated, read-only).
  final String? instrumentKey;

  /// Provider configuration blob.
  final Map<String, dynamic>? providerConfig;

  /// Friendly exchange name derived from the MIC (read-only).
  final String? exchangeName;

  final String createdAt;
  final String updatedAt;

  /// Backwards-compatible symbol accessor — prefers the instrument symbol,
  /// falls back to display code or ID. Used by existing UI that still
  /// references `asset.symbol`.
  String get symbol =>
      instrumentSymbol ?? displayCode ?? id.split(':').last;

  /// Backwards-compatible currency accessor.
  String get currency => quoteCcy;

  factory Asset.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Asset(
      id: parseString(map['id']),
      kind: parseString(map['kind'], fallback: 'OTHER'),
      name: map['name'] as String?,
      displayCode: map['displayCode'] as String?,
      notes: map['notes'] as String?,
      metadata: _nullableMap(map['metadata']),
      isActive: parseBool(map['isActive'], fallback: true),
      quoteMode: parseString(map['quoteMode'], fallback: 'MARKET'),
      quoteCcy: parseString(map['quoteCcy']),
      instrumentType: map['instrumentType'] as String?,
      instrumentSymbol: map['instrumentSymbol'] as String?,
      instrumentExchangeMic: map['instrumentExchangeMic'] as String?,
      instrumentKey: map['instrumentKey'] as String?,
      providerConfig: _nullableMap(map['providerConfig']),
      exchangeName: map['exchangeName'] as String?,
      createdAt: parseString(map['createdAt']),
      updatedAt: parseString(map['updatedAt']),
    );
  }
}

Map<String, dynamic>? _nullableMap(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map<String, dynamic>(
      (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
    );
  }
  return null;
}
