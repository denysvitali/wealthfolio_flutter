import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    this.group,
    required this.currency,
    required this.isDefault,
    required this.isActive,
    required this.isArchived,
    required this.trackingMode,
    required this.createdAt,
    required this.updatedAt,
    this.platformId,
    this.accountNumber,
    this.meta,
    this.provider,
    this.providerAccountId,
  });

  final String id;
  final String name;

  /// e.g. 'BROKERAGE', 'SAVINGS', 'CHECKING', 'CRYPTO', etc.
  final String accountType;

  final String? group;
  final String currency;
  final bool isDefault;
  final bool isActive;
  final bool isArchived;

  /// e.g. 'Transactions', 'Holdings', 'NotSet'
  final String trackingMode;

  final String createdAt;
  final String updatedAt;
  final String? platformId;
  final String? accountNumber;
  final String? meta;
  final String? provider;
  final String? providerAccountId;

  factory Account.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Account(
      id: parseString(map['id']),
      name: parseString(map['name']),
      accountType: parseString(map['account_type']),
      group: map['group'] as String?,
      currency: parseString(map['currency']),
      isDefault: parseBool(map['is_default']),
      isActive: parseBool(map['is_active'], fallback: true),
      isArchived: parseBool(map['is_archived']),
      trackingMode: parseString(map['tracking_mode'], fallback: 'NotSet'),
      createdAt: parseString(map['created_at']),
      updatedAt: parseString(map['updated_at']),
      platformId: map['platform_id'] as String?,
      accountNumber: map['account_number'] as String?,
      meta: map['meta'] as String?,
      provider: map['provider'] as String?,
      providerAccountId: map['provider_account_id'] as String?,
    );
  }
}
