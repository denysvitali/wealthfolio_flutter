import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';

void main() {
  group('Activity.fromJson', () {
    final validJson = <String, dynamic>{
      'id': 'act-1',
      'accountId': 'acc-1',
      'assetId': 'AAPL',
      'activityType': 'BUY',
      'date': '2024-03-15',
      'quantity': 10.0,
      'unitPrice': 175.50,
      'currency': 'USD',
      'fee': 0.99,
      'status': 'POSTED',
      'comment': 'Regular purchase',
      'createdAt': '2024-03-15T10:00:00Z',
      'updatedAt': '2024-03-15T10:00:00Z',
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
        ..['unitPrice'] = '200.00'
        ..['fee'] = '1';

      final activity = Activity.fromJson(json);
      expect(activity.quantity, 5.0);
      expect(activity.unitPrice, 200.0);
      expect(activity.fee, 1.0);
    });

    test('recognizes DRAFT status', () {
      final json = Map<String, dynamic>.from(validJson)
        ..['status'] = 'DRAFT';

      final activity = Activity.fromJson(json);
      expect(activity.isDraft, true);
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
    test('parses activities list and totalRowCount from nested meta', () {
      final json = <String, dynamic>{
        'data': [
          <String, dynamic>{
            'id': 'act-1',
            'accountId': 'acc-1',
            'assetId': 'AAPL',
            'activityType': 'BUY',
            'date': '2024-03-15',
            'quantity': 10.0,
            'unitPrice': 175.50,
            'currency': 'USD',
            'fee': 0.0,
            'status': 'POSTED',
            'createdAt': '',
            'updatedAt': '',
          },
        ],
        'meta': <String, dynamic>{
          'totalRowCount': 1,
        },
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
