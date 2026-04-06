import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';

void main() {
  group('Account.fromJson', () {
    test('parses a complete valid map', () {
      final json = <String, dynamic>{
        'id': 'acc-1',
        'name': 'My Brokerage',
        'account_type': 'BROKERAGE',
        'group': 'Taxable',
        'currency': 'USD',
        'is_default': true,
        'is_active': true,
        'is_archived': false,
        'tracking_mode': 'Transactions',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-06-01T00:00:00Z',
        'platform_id': 'plat-1',
        'account_number': '123456789',
        'meta': null,
        'provider': 'Fidelity',
        'provider_account_id': 'fid-99',
      };

      final account = Account.fromJson(json);

      expect(account.id, 'acc-1');
      expect(account.name, 'My Brokerage');
      expect(account.accountType, 'BROKERAGE');
      expect(account.group, 'Taxable');
      expect(account.currency, 'USD');
      expect(account.isDefault, true);
      expect(account.isActive, true);
      expect(account.isArchived, false);
      expect(account.trackingMode, 'Transactions');
      expect(account.createdAt, '2024-01-01T00:00:00Z');
      expect(account.updatedAt, '2024-06-01T00:00:00Z');
      expect(account.platformId, 'plat-1');
      expect(account.accountNumber, '123456789');
      expect(account.meta, null);
      expect(account.provider, 'Fidelity');
      expect(account.providerAccountId, 'fid-99');
    });

    test('applies sensible defaults for missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'acc-2',
        'name': 'Savings',
        'account_type': 'SAVINGS',
        'currency': 'EUR',
        'created_at': '',
        'updated_at': '',
      };

      final account = Account.fromJson(json);

      expect(account.id, 'acc-2');
      expect(account.isDefault, false);
      expect(account.isActive, true);
      expect(account.isArchived, false);
      expect(account.trackingMode, 'NotSet');
      expect(account.group, null);
      expect(account.platformId, null);
    });

    test('returns empty-string fields when given null input', () {
      final account = Account.fromJson(null);
      expect(account.id, '');
      expect(account.name, '');
      expect(account.currency, '');
    });

    test('handles non-map input gracefully', () {
      final account = Account.fromJson(42);
      expect(account.id, '');
    });
  });
}
