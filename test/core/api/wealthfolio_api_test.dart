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
      // Server struct uses `notes` (accepts `comment` as a serde alias).
      expect(payload['notes'], 'note');
      expect(payload.containsKey('comment'), isFalse);
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

    test('sends symbol as object with quoteCcy for asset-backed activities', () {
      // This is the contract: symbol must be { symbol: 'AAPL', quoteCcy: 'USD' }
      // NOT a plain string. The backend validates quoteCcy is present.
      final payload = normalizeActivityPayloadForRest(<String, dynamic>{
        'account_id': 'acc-1',
        'symbol': <String, dynamic>{
          'symbol': 'AAPL',
          'quoteCcy': 'USD',
        },
        'activity_type': 'BUY',
        'activity_date': '2026-04-07',
        'quantity': 10,
        'unit_price': 150.0,
        'currency': 'USD',
        'fee': 0,
        'is_draft': false,
      });

      expect(payload['symbol'], <String, dynamic>{
        'symbol': 'AAPL',
        'quoteCcy': 'USD',
      });
      expect(payload['activityType'], 'BUY');
      expect(payload['quantity'], '10');
      expect(payload['unitPrice'], '150');
    });

    test('plain-string symbol gets normalized but quoteCcy must be added by caller', () {
      // Sending a plain string symbol (old broken behavior) should NOT include quoteCcy.
      // The fix sends an object { symbol, quoteCcy } — this test documents the old behavior.
      final payload = normalizeActivityPayloadForRest(<String, dynamic>{
        'account_id': 'acc-1',
        'symbol': 'AAPL', // plain string — no quoteCcy
        'activity_type': 'BUY',
        'activity_date': '2026-04-07',
        'quantity': 10,
        'unit_price': 150.0,
        'currency': 'USD',
        'fee': 0,
        'is_draft': false,
      });

      // normalizeActivityPayloadForRest wraps it in {symbol: 'AAPL'} but no quoteCcy.
      // This is the pre-fix behavior. The caller (activity_form_screen.dart) is
      // responsible for including quoteCcy when sending an asset-backed activity.
      expect(payload['symbol'], <String, dynamic>{'symbol': 'AAPL'});
      expect((payload['symbol'] as Map<String, dynamic>).containsKey('quoteCcy'), isFalse);
    });
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
