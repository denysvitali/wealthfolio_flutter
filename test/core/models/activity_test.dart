import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';

void main() {
  group('Activity.fromJson', () {
    final validJson = <String, dynamic>{
      'id': 'act-1',
      'account_id': 'acc-1',
      'asset_id': 'AAPL',
      'activity_type': 'BUY',
      'activity_date': '2024-03-15',
      'quantity': 10.0,
      'unit_price': 175.50,
      'currency': 'USD',
      'fee': 0.99,
      'is_draft': false,
      'comment': 'Regular purchase',
      'created_at': '2024-03-15T10:00:00Z',
      'updated_at': '2024-03-15T10:00:00Z',
    };

    test('parses a complete valid activity', () {
      final activity = Activity.fromJson(validJson);

      expect(activity.id, 'act-1');
      expect(activity.accountId, 'acc-1');
      expect(activity.assetId, 'AAPL');
      expect(activity.activityType, 'BUY');
      expect(activity.activityDate, '2024-03-15');
      expect(activity.quantity, 10.0);
      expect(activity.unitPrice, 175.50);
      expect(activity.currency, 'USD');
      expect(activity.fee, 0.99);
      expect(activity.isDraft, false);
      expect(activity.comment, 'Regular purchase');
    });

    test('parses quantity and price from string values', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['quantity'] = '5'
        ..['unit_price'] = '200.00'
        ..['fee'] = '1';

      final activity = Activity.fromJson(json);
      expect(activity.quantity, 5.0);
      expect(activity.unitPrice, 200.0);
      expect(activity.fee, 1.0);
    });

    test('defaults numeric fields to 0.0 when absent', () {
      final activity = Activity.fromJson(<String, dynamic>{});
      expect(activity.quantity, 0.0);
      expect(activity.unitPrice, 0.0);
      expect(activity.fee, 0.0);
      expect(activity.isDraft, false);
      expect(activity.comment, null);
    });

    test('handles null input', () {
      final activity = Activity.fromJson(null);
      expect(activity.id, '');
      expect(activity.activityType, '');
    });
  });

  group('ActivitySearchResponse.fromJson', () {
    test('parses activities list and total', () {
      final json = <String, dynamic>{
        'activities': [
          <String, dynamic>{
            'id': 'act-1',
            'account_id': 'acc-1',
            'asset_id': 'AAPL',
            'activity_type': 'BUY',
            'activity_date': '2024-03-15',
            'quantity': 10.0,
            'unit_price': 175.50,
            'currency': 'USD',
            'fee': 0.0,
            'is_draft': false,
            'created_at': '',
            'updated_at': '',
          },
        ],
        'total': 1,
      };

      final response = ActivitySearchResponse.fromJson(json);
      expect(response.total, 1);
      expect(response.activities.length, 1);
      expect(response.activities.first.id, 'act-1');
    });

    test('returns empty list and zero total for null input', () {
      final response = ActivitySearchResponse.fromJson(null);
      expect(response.activities, isEmpty);
      expect(response.total, 0);
    });
  });
}
