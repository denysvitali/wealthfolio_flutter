import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// A single issue surfaced by the portfolio health checker. Only the fields
/// actually consumed by the Flutter client are modelled here; unknown
/// fields are ignored.
class HealthIssue {
  const HealthIssue({
    required this.id,
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    required this.affectedCount,
    this.affectedMvPct,
    this.details,
    required this.dataHash,
    required this.timestamp,
  });

  final String id;

  /// `INFO`, `WARNING`, `ERROR`, or `CRITICAL`.
  final String severity;

  /// `PRICE_STALENESS`, `FX_INTEGRITY`, `CLASSIFICATION`,
  /// `DATA_CONSISTENCY`, `ACCOUNT_CONFIGURATION`, `SETTINGS_CONFIGURATION`.
  final String category;

  final String title;
  final String message;
  final int affectedCount;

  /// Fraction of total portfolio market value affected (0.0 – 1.0).
  final double? affectedMvPct;

  final String? details;

  /// Hash of the underlying data; used to restore issues when data changes.
  final String dataHash;

  /// ISO timestamp at which the issue was detected.
  final String timestamp;

  factory HealthIssue.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return HealthIssue(
      id: parseString(map['id']),
      severity: parseString(map['severity'], fallback: 'INFO'),
      category: parseString(map['category']),
      title: parseString(map['title']),
      message: parseString(map['message']),
      affectedCount: parseInt(map['affectedCount']),
      affectedMvPct: map['affectedMvPct'] == null
          ? null
          : parseDouble(map['affectedMvPct']),
      details: map['details'] as String?,
      dataHash: parseString(map['dataHash']),
      timestamp: parseString(map['timestamp']),
    );
  }
}

/// Aggregated health status returned by `GET /api/v1/health/status` and
/// `POST /api/v1/health/check`.
class HealthStatus {
  const HealthStatus({
    required this.overallSeverity,
    required this.issueCounts,
    required this.issues,
    required this.checkedAt,
    required this.isStale,
  });

  /// The highest severity across all issues.
  final String overallSeverity;

  /// Count of issues at each severity level.
  final Map<String, int> issueCounts;

  final List<HealthIssue> issues;

  /// ISO timestamp at which the checks were last run.
  final String checkedAt;

  /// True when the cached results are older than ~5 minutes.
  final bool isStale;

  factory HealthStatus.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawCounts = parseMap(map['issueCounts']);
    return HealthStatus(
      overallSeverity: parseString(map['overallSeverity'], fallback: 'INFO'),
      issueCounts: <String, int>{
        for (final entry in rawCounts.entries)
          entry.key: parseInt(entry.value),
      },
      issues: parseList(map['issues']).map(HealthIssue.fromJson).toList(),
      checkedAt: parseString(map['checkedAt']),
      isStale: parseBool(map['isStale']),
    );
  }
}
