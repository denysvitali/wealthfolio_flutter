import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Asset {
  const Asset({
    required this.id,
    this.isin,
    required this.name,
    required this.assetType,
    required this.symbol,
    this.symbolMapping,
    this.assetClass,
    this.assetSubClass,
    this.comment,
    this.countries,
    this.categories,
    this.classes,
    this.attributes,
    required this.currency,
    required this.dataSource,
    this.sectors,
    this.url,
    required this.quoteMode,
  });

  final String id;
  final String? isin;
  final String name;

  /// e.g. 'EQUITY', 'ETF', 'MUTUAL_FUND', 'CRYPTO', 'CURRENCY', 'CASH'
  final String assetType;

  final String symbol;
  final String? symbolMapping;
  final String? assetClass;
  final String? assetSubClass;
  final String? comment;

  /// JSON-encoded string or structured data from the API
  final String? countries;
  final String? categories;
  final String? classes;
  final String? attributes;

  final String currency;

  /// e.g. 'YAHOO', 'MANUAL', 'COINGECKO', etc.
  final String dataSource;

  final String? sectors;
  final String? url;

  /// e.g. 'AUTO', 'MANUAL', 'YAHOO_FINANCE'
  final String quoteMode;

  factory Asset.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Asset(
      id: parseString(map['id']),
      isin: map['isin'] as String?,
      name: parseString(map['name']),
      assetType: parseString(map['asset_type']),
      symbol: parseString(map['symbol']),
      symbolMapping: map['symbol_mapping'] as String?,
      assetClass: map['asset_class'] as String?,
      assetSubClass: map['asset_sub_class'] as String?,
      comment: map['comment'] as String?,
      countries: map['countries'] as String?,
      categories: map['categories'] as String?,
      classes: map['classes'] as String?,
      attributes: map['attributes'] as String?,
      currency: parseString(map['currency']),
      dataSource: parseString(map['data_source']),
      sectors: map['sectors'] as String?,
      url: map['url'] as String?,
      quoteMode: parseString(map['quote_mode'], fallback: 'AUTO'),
    );
  }
}
