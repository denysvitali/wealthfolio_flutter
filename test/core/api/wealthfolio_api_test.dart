import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/api/wealthfolio_api.dart';

void main() {
  group('normalizeActivityPayloadForRest', () {
    test('maps legacy snake_case activity payloads to REST format', () {
      final payload = normalizeActivityPayloadForRest(<String, dynamic>{
        'account_id': 'acc-1',
        'symbol': 'AAPL',
        'activity_type': 'BUY',
        'activity_date': '2026-04-07',
        'quantity': 2,
        'unit_price': 150.5,
        'currency': 'usd',
        'fee': 1.25,
        'is_draft': true,
        'comment': 'note',
      });

      expect(payload['accountId'], 'acc-1');
      expect(payload['activityType'], 'BUY');
      expect(payload['activityDate'], '2026-04-07');
      expect(payload['currency'], 'USD');
      expect(payload['quantity'], '2');
      expect(payload['unitPrice'], '150.5');
      expect(payload['fee'], '1.25');
      expect(payload['status'], 'DRAFT');
      expect(payload['comment'], 'note');
      expect(payload['symbol'], <String, dynamic>{'symbol': 'AAPL'});
    });

    test(
      'derives amount for amount-driven activities and json-encodes metadata',
      () {
        final payload = normalizeActivityPayloadForRest(<String, dynamic>{
          'account_id': 'acc-1',
          'activity_type': 'DEPOSIT',
          'activity_date': '2026-04-07',
          'quantity': 3,
          'unit_price': 125.5,
          'currency': 'usd',
          'metadata': <String, dynamic>{
            'flow': <String, dynamic>{'is_external': true},
          },
        });

        expect(payload['amount'], '376.5');
        expect(jsonDecode(payload['metadata'] as String), <String, dynamic>{
          'flow': <String, dynamic>{'is_external': true},
        });
      },
    );
  });

  group('normalizeAccountPayloadForRest', () {
    test('maps account payloads to camelCase REST fields', () {
      final payload = normalizeAccountPayloadForRest(<String, dynamic>{
        'name': 'Main',
        'account_type': 'cash',
        'currency': 'usd',
        'is_default': true,
        'is_active': true,
        'tracking_mode': 'notset',
      });

      expect(payload['name'], 'Main');
      expect(payload['accountType'], 'CASH');
      expect(payload['currency'], 'USD');
      expect(payload['isDefault'], true);
      expect(payload['isActive'], true);
      expect(payload['trackingMode'], 'NOT_SET');
    });
  });
}
