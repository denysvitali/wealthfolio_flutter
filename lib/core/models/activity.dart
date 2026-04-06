import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

class Activity {
  const Activity({
    required this.id,
    required this.accountId,
    required this.assetId,
    required this.activityType,
    required this.activityDate,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
    required this.fee,
    required this.isDraft,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String accountId;
  final String assetId;

  /// e.g. 'BUY', 'SELL', 'DIVIDEND', 'INTEREST', 'DEPOSIT', 'WITHDRAWAL',
  /// 'TRANSFER_IN', 'TRANSFER_OUT', 'CONVERSION_IN', 'CONVERSION_OUT', 'FEE'
  final String activityType;

  final String activityDate;
  final double quantity;
  final double unitPrice;
  final String currency;
  final double fee;
  final bool isDraft;
  final String? comment;
  final String createdAt;
  final String updatedAt;

  factory Activity.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Activity(
      id: parseString(map['id']),
      accountId: parseString(map['accountId'] ?? map['account_id']),
      assetId: parseString(
        map['assetId'] ?? map['asset_id'] ?? map['symbol'],
      ),
      activityType: parseString(map['activityType'] ?? map['activity_type']),
      activityDate: parseString(map['date'] ?? map['activityDate'] ?? map['activity_date']),
      quantity: parseDouble(map['quantity']),
      unitPrice: parseDouble(map['unitPrice'] ?? map['unit_price']),
      currency: parseString(map['currency']),
      fee: parseDouble(map['fee']),
      isDraft: parseBool(map['isDraft'] ?? map['is_draft']) ||
          parseString(map['status']).toUpperCase() == 'DRAFT',
      comment: map['comment'] as String?,
      createdAt: parseString(map['createdAt'] ?? map['created_at']),
      updatedAt: parseString(map['updatedAt'] ?? map['updated_at']),
    );
  }
}

class ActivitySearchResponse {
  const ActivitySearchResponse({
    required this.activities,
    required this.total,
  });

  final List<Activity> activities;
  final int total;

  factory ActivitySearchResponse.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawList = parseList(map['data']);
    final meta = parseMap(map['meta']);
    return ActivitySearchResponse(
      activities: rawList.map(Activity.fromJson).toList(),
      total: parseInt(meta['totalRowCount']),
    );
  }
}
