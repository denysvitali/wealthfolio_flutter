import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class PortfolioAllocation {
  const PortfolioAllocation({
    required this.name,
    required this.value,
    required this.percentage,
    this.color,
  });

  final String name;
  final double value;
  final double percentage;

  /// Optional hex color string, e.g. '#4e9af1'
  final String? color;

  factory PortfolioAllocation.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return PortfolioAllocation(
      name: parseString(map['name']),
      value: parseDouble(map['value']),
      percentage: parseDouble(map['percentage']),
      color: map['color'] as String?,
    );
  }
}

class AllocationHoldings {
  const AllocationHoldings({required this.holdings});

  final List<Holding> holdings;

  factory AllocationHoldings.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawList = parseList(map['holdings']);
    return AllocationHoldings(
      holdings: rawList.map(Holding.fromJson).toList(),
    );
  }
}
