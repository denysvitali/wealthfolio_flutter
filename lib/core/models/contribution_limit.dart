import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// Contribution limit for a group of accounts. Mirrors the Axum server's
/// `ContributionLimit` (camelCase).
///
/// Note: the server stores `accountIds` as a comma-separated string — we
/// expose both the raw string (`accountIdsRaw`) and a parsed list for
/// convenience.
class ContributionLimit {
  const ContributionLimit({
    required this.id,
    required this.groupName,
    required this.contributionYear,
    required this.limitAmount,
    this.accountIdsRaw,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupName;
  final int contributionYear;
  final double limitAmount;

  /// Raw comma-separated account IDs as stored by the server. `null` when no
  /// accounts are assigned.
  final String? accountIdsRaw;

  /// ISO date (YYYY-MM-DD) marking the start of the contribution window.
  final String? startDate;

  /// ISO date (YYYY-MM-DD) marking the end of the contribution window.
  final String? endDate;

  final String createdAt;
  final String updatedAt;

  /// Convenience: parsed list of account IDs (trimmed, non-empty).
  List<String> get accountIds {
    final raw = accountIdsRaw;
    if (raw == null || raw.isEmpty) return const <String>[];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  factory ContributionLimit.fromJson(dynamic raw) {
    final map = parseMap(raw);

    // Server sends a comma-separated string; accept a list as a defensive
    // fallback in case a caller (or test fixture) hands us one.
    String? accountIdsRawValue;
    final rawIds = map['accountIds'] ?? map['account_ids'];
    if (rawIds is String) {
      accountIdsRawValue = rawIds.isEmpty ? null : rawIds;
    } else if (rawIds is List) {
      final joined = rawIds.map((e) => e.toString().trim()).join(',');
      accountIdsRawValue = joined.isEmpty ? null : joined;
    }

    return ContributionLimit(
      id: parseString(map['id']),
      groupName: parseString(map['groupName'] ?? map['group_name']),
      contributionYear: parseInt(
        map['contributionYear'] ?? map['contribution_year'],
      ),
      limitAmount: parseDouble(map['limitAmount'] ?? map['limit_amount']),
      accountIdsRaw: accountIdsRawValue,
      startDate: (map['startDate'] ?? map['start_date']) as String?,
      endDate: (map['endDate'] ?? map['end_date']) as String?,
      createdAt: parseString(map['createdAt'] ?? map['created_at']),
      updatedAt: parseString(map['updatedAt'] ?? map['updated_at']),
    );
  }
}

/// A single account's share of a contribution-limit calculation.
class AccountDeposit {
  const AccountDeposit({
    required this.amount,
    required this.currency,
    required this.convertedAmount,
  });

  final double amount;
  final String currency;
  final double convertedAmount;

  factory AccountDeposit.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return AccountDeposit(
      amount: parseDouble(map['amount']),
      currency: parseString(map['currency']),
      convertedAmount: parseDouble(map['convertedAmount']),
    );
  }
}

/// Response from `GET /api/v1/limits/{id}/deposits`.
class DepositsCalculation {
  const DepositsCalculation({
    required this.total,
    required this.baseCurrency,
    required this.byAccount,
  });

  final double total;
  final String baseCurrency;
  final Map<String, AccountDeposit> byAccount;

  factory DepositsCalculation.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final byAccountMap = parseMap(map['byAccount']);
    return DepositsCalculation(
      total: parseDouble(map['total']),
      baseCurrency: parseString(map['baseCurrency']),
      byAccount: <String, AccountDeposit>{
        for (final entry in byAccountMap.entries)
          entry.key: AccountDeposit.fromJson(entry.value),
      },
    );
  }
}
