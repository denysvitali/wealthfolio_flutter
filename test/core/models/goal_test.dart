import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/goal.dart';

void main() {
  group('Goal.fromJson', () {
    test('parses a complete goal', () {
      final json = <String, dynamic>{
        'id': 'goal-1',
        'title': 'Retirement Fund',
        'description': 'Save for retirement by 2045',
        'target_amount': 1000000.0,
        'is_achieved': false,
      };

      final goal = Goal.fromJson(json);
      expect(goal.id, 'goal-1');
      expect(goal.title, 'Retirement Fund');
      expect(goal.description, 'Save for retirement by 2045');
      expect(goal.targetAmount, 1000000.0);
      expect(goal.isAchieved, false);
    });

    test('description is null when absent', () {
      final goal = Goal.fromJson(<String, dynamic>{
        'id': 'g-2',
        'title': 'Emergency Fund',
        'target_amount': 10000.0,
        'is_achieved': true,
      });

      expect(goal.description, null);
      expect(goal.isAchieved, true);
    });

    test('handles null input', () {
      final goal = Goal.fromJson(null);
      expect(goal.id, '');
      expect(goal.targetAmount, 0.0);
      expect(goal.isAchieved, false);
    });
  });
}
