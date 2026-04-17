import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/contribution_limit.dart';

void main() {
  group('ContributionLimit.fromJson', () {
    test('parses the server camelCase payload', () {
      final json = <String, dynamic>{
        'id': 'cl-1',
        'groupName': 'TFSA',
        'contributionYear': 2024,
        'limitAmount': 7000.0,
        'accountIds': 'acc-1,acc-2',
        'startDate': '2024-01-01',
        'endDate': '2024-12-31',
        'createdAt': '2024-01-01T00:00:00',
        'updatedAt': '2024-04-01T00:00:00',
      };

      final limit = ContributionLimit.fromJson(json);
      expect(limit.id, 'cl-1');
      expect(limit.groupName, 'TFSA');
      expect(limit.contributionYear, 2024);
      expect(limit.limitAmount, 7000.0);
      expect(limit.accountIdsRaw, 'acc-1,acc-2');
      expect(limit.accountIds, ['acc-1', 'acc-2']);
      expect(limit.startDate, '2024-01-01');
      expect(limit.endDate, '2024-12-31');
    });

    test('accepts legacy snake_case and a list fallback for accountIds', () {
      final limit = ContributionLimit.fromJson(<String, dynamic>{
        'id': 'cl-legacy',
        'group_name': 'RRSP',
        'contribution_year': 2024,
        'limit_amount': 30780.0,
        'account_ids': ['acc-1', '', 'acc-2'],
      });
      expect(limit.groupName, 'RRSP');
      expect(limit.accountIds, ['acc-1', 'acc-2']);
    });

    test('leaves accountIdsRaw null when the server omits the field', () {
      final limit = ContributionLimit.fromJson(<String, dynamic>{
        'id': 'cl-2',
        'groupName': 'FHSA',
        'contributionYear': 2024,
        'limitAmount': 8000.0,
      });
      expect(limit.accountIdsRaw, isNull);
      expect(limit.accountIds, isEmpty);
    });

    test('handles null input', () {
      final limit = ContributionLimit.fromJson(null);
      expect(limit.id, '');
      expect(limit.contributionYear, 0);
      expect(limit.limitAmount, 0.0);
      expect(limit.accountIds, isEmpty);
    });
  });

  group('DepositsCalculation.fromJson', () {
    test('parses total and per-account breakdown', () {
      final json = <String, dynamic>{
        'total': 6500.0,
        'baseCurrency': 'USD',
        'byAccount': <String, dynamic>{
          'acc-1': <String, dynamic>{
            'amount': 5000.0,
            'currency': 'USD',
            'convertedAmount': 5000.0,
          },
          'acc-2': <String, dynamic>{
            'amount': 1500.0,
            'currency': 'EUR',
            'convertedAmount': 1650.0,
          },
        },
      };

      final calc = DepositsCalculation.fromJson(json);
      expect(calc.total, 6500.0);
      expect(calc.baseCurrency, 'USD');
      expect(calc.byAccount['acc-1']?.amount, 5000.0);
      expect(calc.byAccount['acc-2']?.currency, 'EUR');
      expect(calc.byAccount['acc-2']?.convertedAmount, 1650.0);
    });
  });
}
