import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/contribution_limit.dart';

void main() {
  group('ContributionLimit.fromJson', () {
    test('parses all fields including account_ids', () {
      final json = <String, dynamic>{
        'id': 'cl-1',
        'group_name': 'TFSA',
        'contribution_year': 2024,
        'limit_amount': 7000.0,
        'account_ids': ['acc-1', 'acc-2'],
      };

      final limit = ContributionLimit.fromJson(json);
      expect(limit.id, 'cl-1');
      expect(limit.groupName, 'TFSA');
      expect(limit.contributionYear, 2024);
      expect(limit.limitAmount, 7000.0);
      expect(limit.accountIds, ['acc-1', 'acc-2']);
    });

    test('leaves accountIds null when field is absent', () {
      final json = <String, dynamic>{
        'id': 'cl-2',
        'group_name': 'RRSP',
        'contribution_year': 2024,
        'limit_amount': 30780.0,
      };

      final limit = ContributionLimit.fromJson(json);
      expect(limit.accountIds, null);
    });

    test('filters out empty strings from account_ids', () {
      final json = <String, dynamic>{
        'id': 'cl-3',
        'group_name': 'FHSA',
        'contribution_year': 2024,
        'limit_amount': 8000.0,
        'account_ids': ['acc-1', '', '  '],
      };

      final limit = ContributionLimit.fromJson(json);
      // '' and '  ' both produce '' after parseString, filtered by isNotEmpty
      expect(limit.accountIds, ['acc-1']);
    });

    test('handles null input', () {
      final limit = ContributionLimit.fromJson(null);
      expect(limit.id, '');
      expect(limit.contributionYear, 0);
      expect(limit.limitAmount, 0.0);
      expect(limit.accountIds, null);
    });
  });
}
