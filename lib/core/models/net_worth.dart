import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class NetWorthBreakdownItem {
  const NetWorthBreakdownItem({
    required this.category,
    required this.name,
    required this.value,
    this.assetId,
  });

  /// Category key (e.g. 'cash', 'investments', 'properties', 'vehicles',
  /// 'collectibles', 'preciousMetals', 'otherAssets', 'liability').
  final String category;

  /// Display name (e.g. 'Cash', 'Investments').
  final String name;

  /// Value in base currency (positive magnitude).
  final double value;

  /// Optional asset ID for individual items (e.g. specific liabilities).
  final String? assetId;

  factory NetWorthBreakdownItem.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return NetWorthBreakdownItem(
      category: parseString(map['category']),
      name: parseString(map['name']),
      value: parseDouble(map['value']),
      assetId: map['assetId'] as String?,
    );
  }
}

class NetWorthSection {
  const NetWorthSection({required this.total, required this.breakdown});

  final double total;
  final List<NetWorthBreakdownItem> breakdown;

  factory NetWorthSection.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawList = parseList(map['breakdown']);
    return NetWorthSection(
      total: parseDouble(map['total']),
      breakdown: rawList.map(NetWorthBreakdownItem.fromJson).toList(),
    );
  }

  static const NetWorthSection empty = NetWorthSection(
    total: 0,
    breakdown: <NetWorthBreakdownItem>[],
  );
}

class StaleAssetInfo {
  const StaleAssetInfo({
    required this.assetId,
    this.name,
    required this.valuationDate,
    required this.daysStale,
  });

  final String assetId;
  final String? name;
  final String valuationDate;
  final int daysStale;

  factory StaleAssetInfo.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return StaleAssetInfo(
      assetId: parseString(map['assetId']),
      name: map['name'] as String?,
      valuationDate: parseString(map['valuationDate']),
      daysStale: parseInt(map['daysStale']),
    );
  }
}

/// Response from `GET /api/v1/net-worth`. Shape mirrors the Axum server's
/// balance-sheet model (camelCase JSON).
class NetWorthResponse {
  const NetWorthResponse({
    required this.date,
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.currency,
    this.oldestValuationDate,
    this.staleAssets = const <StaleAssetInfo>[],
  });

  final String date;
  final NetWorthSection assets;
  final NetWorthSection liabilities;
  final double netWorth;
  final String currency;
  final String? oldestValuationDate;
  final List<StaleAssetInfo> staleAssets;

  /// Alias: total net worth (assets.total - liabilities.total).
  double get total => netWorth;

  double _sumBreakdown(Set<String> categoryKeys) {
    double sum = 0;
    for (final item in assets.breakdown) {
      if (categoryKeys.contains(item.category)) sum += item.value;
    }
    return sum;
  }

  /// Derived: investments sub-total from the assets breakdown.
  double get investmentsTotal => _sumBreakdown(const {'investments'});

  /// Derived: cash sub-total from the assets breakdown.
  double get cashTotal => _sumBreakdown(const {'cash'});

  /// Derived: alternative assets sub-total (properties + vehicles +
  /// collectibles + preciousMetals + otherAssets).
  double get alternativesTotal => _sumBreakdown(const {
        'properties',
        'vehicles',
        'collectibles',
        'preciousMetals',
        'otherAssets',
      });

  double get assetsTotal => assets.total;
  double get liabilitiesTotal => liabilities.total;

  factory NetWorthResponse.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final staleList = parseList(map['staleAssets']);
    return NetWorthResponse(
      date: parseString(map['date']),
      assets: NetWorthSection.fromJson(map['assets']),
      liabilities: NetWorthSection.fromJson(map['liabilities']),
      netWorth: parseDouble(map['netWorth']),
      currency: parseString(map['currency']),
      oldestValuationDate: map['oldestValuationDate'] as String?,
      staleAssets: staleList.map(StaleAssetInfo.fromJson).toList(),
    );
  }
}

/// Response item from `GET /api/v1/net-worth/history`. Shape mirrors the
/// Axum server's `NetWorthHistoryPoint` (camelCase JSON).
class NetWorthHistoryPoint {
  const NetWorthHistoryPoint({
    required this.date,
    required this.portfolioValue,
    required this.alternativeAssetsValue,
    required this.totalLiabilities,
    required this.totalAssets,
    required this.netWorth,
    required this.netContribution,
    required this.currency,
  });

  final String date;
  final double portfolioValue;
  final double alternativeAssetsValue;
  final double totalLiabilities;
  final double totalAssets;
  final double netWorth;
  final double netContribution;
  final String currency;

  /// Alias for chart rendering: plotted value is the net worth.
  double get total => netWorth;

  factory NetWorthHistoryPoint.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return NetWorthHistoryPoint(
      date: parseString(map['date']),
      portfolioValue: parseDouble(map['portfolioValue']),
      alternativeAssetsValue: parseDouble(map['alternativeAssetsValue']),
      totalLiabilities: parseDouble(map['totalLiabilities']),
      totalAssets: parseDouble(map['totalAssets']),
      netWorth: parseDouble(map['netWorth']),
      netContribution: parseDouble(map['netContribution']),
      currency: parseString(map['currency']),
    );
  }
}
