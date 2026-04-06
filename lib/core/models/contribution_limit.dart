import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class ContributionLimit {
  const ContributionLimit({
    required this.id,
    required this.groupName,
    required this.contributionYear,
    required this.limitAmount,
    this.accountIds,
  });

  final String id;
  final String groupName;
  final int contributionYear;
  final double limitAmount;

  /// Optional list of account IDs associated with this limit group
  final List<String>? accountIds;

  factory ContributionLimit.fromJson(dynamic raw) {
    final map = parseMap(raw);

    List<String>? accountIds;
    final rawIds = map['account_ids'];
    if (rawIds != null) {
      accountIds = parseList(rawIds)
          .map((e) => parseString(e))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return ContributionLimit(
      id: parseString(map['id']),
      groupName: parseString(map['group_name']),
      contributionYear: parseInt(map['contribution_year']),
      limitAmount: parseDouble(map['limit_amount']),
      accountIds: accountIds,
    );
  }
}
