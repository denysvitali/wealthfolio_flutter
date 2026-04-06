import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.isAchieved,
  });

  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final bool isAchieved;

  factory Goal.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Goal(
      id: parseString(map['id']),
      title: parseString(map['title']),
      description: map['description'] as String?,
      targetAmount: parseDouble(map['targetAmount']),
      isAchieved: parseBool(map['isAchieved']),
    );
  }
}
