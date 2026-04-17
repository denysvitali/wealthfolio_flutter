import 'package:wealthfolio_flutter/core/api/wealthfolio_api.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/models/asset.dart';
import 'package:wealthfolio_flutter/core/models/contribution_limit.dart';
import 'package:wealthfolio_flutter/core/models/exchange_rate.dart';
import 'package:wealthfolio_flutter/core/models/goal.dart';
import 'package:wealthfolio_flutter/core/models/health_status.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/models/quote.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';
import 'package:wealthfolio_flutter/core/models/settings.dart';
import 'package:wealthfolio_flutter/core/models/taxonomy.dart';
import 'package:wealthfolio_flutter/core/models/valuation.dart';

class FakeWealthfolioApi implements WealthfolioApi {
  FakeWealthfolioApi({
    AppSession? signInSession,
    List<Account>? accounts,
    Map<String, List<Holding>>? holdingsByAccountId,
    Settings? settings,
    ActivitySearchResponse? activitiesResponse,
    List<Map<String, dynamic>>? performanceHistory,
    Map<String, dynamic>? allocationsResponse,
  }) : signInSession =
           signInSession ??
           const AppSession(
             serverUrl: 'http://localhost:8088',
             token: 'token',
             username: 'admin',
           ),
       accounts = accounts ?? const <Account>[],
       holdingsByAccountId = holdingsByAccountId ?? const <String, List<Holding>>{},
       settings =
           settings ??
           const Settings(
             id: 'settings',
             theme: 'system',
             font: 'inter',
             baseCurrency: 'USD',
           ),
       activitiesResponse =
           activitiesResponse ??
           const ActivitySearchResponse(
             activities: <Activity>[],
             total: 0,
           ),
       performanceHistory =
           performanceHistory ??
           const <Map<String, dynamic>>[
             <String, dynamic>{'date': '2026-01-01', 'value': 0},
           ],
       allocationsResponse =
           allocationsResponse ??
           const <String, dynamic>{'assetClass': <Map<String, dynamic>>[]};

  AppSession signInSession;
  List<Account> accounts;
  Map<String, List<Holding>> holdingsByAccountId;
  Settings settings;
  ActivitySearchResponse activitiesResponse;
  List<Map<String, dynamic>> performanceHistory;
  Map<String, dynamic> allocationsResponse;

  WealthfolioException? verifyServerError;
  WealthfolioException? signInError;
  WealthfolioException? authStatusError;
  WealthfolioException? createActivityError;
  WealthfolioException? updateActivityError;

  String? lastVerifiedServerUrl;
  String? lastSignInServerUrl;
  String? lastUsername;
  String? lastPassword;

  /// Last activity payload captured by createActivity or updateActivity.
  /// Useful for unit tests to assert on the exact payload structure.
  Map<String, dynamic>? lastActivityPayload;
  String? lastActivityId;
  int fetchAccountsCallCount = 0;
  int fetchSettingsCallCount = 0;

  @override
  Future<void> verifyServer(String serverUrl) async {
    lastVerifiedServerUrl = serverUrl;
    if (verifyServerError != null) {
      throw verifyServerError!;
    }
  }

  @override
  Future<AppSession> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    lastSignInServerUrl = serverUrl;
    lastUsername = username;
    lastPassword = password;
    if (signInError != null) {
      throw signInError!;
    }
    return signInSession;
  }

  @override
  Future<Map<String, dynamic>> getAuthStatus(AppSession session) async {
    if (authStatusError != null) {
      throw authStatusError!;
    }
    return const <String, dynamic>{'authenticated': true};
  }

  @override
  Future<List<Account>> fetchAccounts(
    AppSession session, {
    bool includeArchived = false,
  }) async {
    fetchAccountsCallCount += 1;
    return accounts;
  }

  @override
  Future<List<Holding>> fetchHoldings(
    AppSession session, {
    required String accountId,
  }) async {
    return holdingsByAccountId[accountId] ?? const <Holding>[];
  }

  @override
  Future<Settings> fetchSettings(AppSession session) async {
    fetchSettingsCallCount += 1;
    return settings;
  }

  @override
  Future<ActivitySearchResponse> searchActivities(
    AppSession session, {
    int page = 1,
    int pageSize = 50,
    String? accountId,
    String? activityType,
    String? assetKeyword,
    String? sort,
  }) async {
    return activitiesResponse;
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceHistory(
    AppSession session, {
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
    String? trackingMode,
  }) async {
    return <String, dynamic>{
      'id': itemId,
      'returns': performanceHistory,
      'currency': 'USD',
      'periodGain': 0,
      'simpleReturn': 0,
      'annualizedSimpleReturn': 0,
      'volatility': 0,
      'maxDrawdown': 0,
      'isHoldingsMode': false,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchAllocations(
    AppSession session, {
    String? accountId,
  }) async {
    return allocationsResponse;
  }

  @override
  Future<List<dynamic>> fetchIncomeSummary(
    AppSession session, {
    String? accountId,
  }) async {
    return const <Map<String, dynamic>>[
      <String, dynamic>{
        'period': 'TOTAL',
        'byMonth': <String, dynamic>{},
        'byType': <String, dynamic>{},
        'byAsset': <String, dynamic>{},
        'byCurrency': <String, dynamic>{},
        'byAccount': <String, dynamic>{},
        'totalIncome': 0,
        'currency': 'USD',
        'monthlyAverage': 0,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchNetWorth(
    AppSession session, {
    String? date,
  }) async {
    return const <String, dynamic>{
      'date': '2026-01-01',
      'assets': <String, dynamic>{
        'total': 0,
        'breakdown': <Map<String, dynamic>>[],
      },
      'liabilities': <String, dynamic>{
        'total': 0,
        'breakdown': <Map<String, dynamic>>[],
      },
      'netWorth': 0,
      'currency': 'USD',
      'staleAssets': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNetWorthHistory(
    AppSession session, {
    required String startDate,
    required String endDate,
  }) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceSummary(
    AppSession session, {
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
    String? trackingMode,
  }) async {
    return <String, dynamic>{
      'id': itemId,
      'returns': const <Map<String, dynamic>>[],
      'currency': 'USD',
      'periodGain': 0,
      'simpleReturn': 0,
      'annualizedSimpleReturn': 0,
      'volatility': 0,
      'maxDrawdown': 0,
      'isHoldingsMode': false,
    };
  }

  @override
  Future<Account> createAccount(AppSession session, Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<Account> updateAccount(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteAccount(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<Holding?> fetchHolding(
    AppSession session, {
    required String accountId,
    required String assetId,
  }) => throw UnimplementedError();

  @override
  Future<List<Holding>> fetchHoldingsByAsset(
    AppSession session,
    String assetId,
  ) => throw UnimplementedError();

  @override
  Future<Activity> createActivity(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    if (createActivityError != null) throw createActivityError!;
    lastActivityPayload = Map<String, dynamic>.from(data);
    // Simulate a successful response
    return Activity.fromJson(<String, dynamic>{
      'id': 'fake-activity-${DateTime.now().millisecondsSinceEpoch}',
      'accountId': data['accountId'] ?? data['account_id'] ?? '',
      'assetId': data['symbol'] is Map ? data['symbol']['symbol'] : data['symbol'] ?? '',
      'activityType': data['activityType'] ?? data['activity_type'] ?? 'BUY',
      'activityDate': data['activityDate'] ?? data['activity_date'] ?? '2026-04-07',
      'quantity': data['quantity'] ?? 0,
      'unitPrice': data['unitPrice'] ?? data['unit_price'] ?? 0,
      'amount': data['amount'] ?? 0,
      'currency': data['currency'] ?? 'USD',
      'fee': data['fee'] ?? 0,
      'isDraft': data['isDraft'] ?? data['is_draft'] ?? false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Activity> updateActivity(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    if (updateActivityError != null) throw updateActivityError!;
    lastActivityPayload = Map<String, dynamic>.from(data);
    lastActivityId = data['id']?.toString();
    return Activity.fromJson(<String, dynamic>{
      'id': data['id'] ?? 'fake-activity-${DateTime.now().millisecondsSinceEpoch}',
      'accountId': data['accountId'] ?? data['account_id'] ?? '',
      'assetId': data['symbol'] is Map ? data['symbol']['symbol'] : data['symbol'] ?? '',
      'activityType': data['activityType'] ?? data['activity_type'] ?? 'BUY',
      'activityDate': data['activityDate'] ?? data['activity_date'] ?? '2026-04-07',
      'quantity': data['quantity'] ?? 0,
      'unitPrice': data['unitPrice'] ?? data['unit_price'] ?? 0,
      'amount': data['amount'] ?? 0,
      'currency': data['currency'] ?? 'USD',
      'fee': data['fee'] ?? 0,
      'isDraft': data['isDraft'] ?? data['is_draft'] ?? false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteActivity(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchSimplePerformance(
    AppSession session,
    List<String> accountIds,
  ) => throw UnimplementedError();

  @override
  Future<Settings> updateSettings(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final nextCurrency = data['baseCurrency']?.toString();
    if (nextCurrency != null) {
      settings = Settings(
        id: settings.id,
        theme: settings.theme,
        font: settings.font,
        baseCurrency: nextCurrency,
      );
    }
    return settings;
  }

  @override
  Future<void> updatePortfolio(AppSession session) => throw UnimplementedError();

  @override
  Future<void> recalculatePortfolio(AppSession session) =>
      throw UnimplementedError();

  @override
  Future<List<Goal>> fetchGoals(AppSession session) async => const <Goal>[];

  @override
  Future<Goal> createGoal(AppSession session, Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<Goal> updateGoal(AppSession session, Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<void> deleteGoal(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<List<ExchangeRate>> fetchExchangeRates(AppSession session) =>
      throw UnimplementedError();

  @override
  Future<ExchangeRate> addExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<ExchangeRate> updateExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteExchangeRate(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> searchSymbol(
    AppSession session,
    String query,
  ) => throw UnimplementedError();

  @override
  Future<void> syncMarketData(AppSession session) => throw UnimplementedError();

  @override
  Future<List<Asset>> fetchAssets(AppSession session) => throw UnimplementedError();

  @override
  Future<Asset> fetchAssetProfile(AppSession session, String assetId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchAllocationHoldings(
    AppSession session, {
    required String accountId,
    required String taxonomyId,
    required String categoryId,
  }) => throw UnimplementedError();

  // ---- Auth: logout / me ----

  @override
  Future<Map<String, dynamic>> getAuthMe(AppSession session) async =>
      const <String, dynamic>{'username': 'admin', 'authenticated': true};

  @override
  Future<void> signOut(AppSession session) async {}

  // ---- Valuations ----

  @override
  Future<List<DailyAccountValuation>> fetchValuationHistory(
    AppSession session, {
    required String accountId,
    String? startDate,
    String? endDate,
  }) async => const <DailyAccountValuation>[];

  @override
  Future<List<DailyAccountValuation>> fetchLatestValuations(
    AppSession session, {
    List<String>? accountIds,
  }) async => const <DailyAccountValuation>[];

  // ---- Market data (quotes / providers / exchanges) ----

  @override
  Future<List<Quote>> fetchQuoteHistory(
    AppSession session,
    String symbol,
  ) async => const <Quote>[];

  @override
  Future<Map<String, dynamic>> fetchLatestQuotes(
    AppSession session,
    List<String> symbols,
  ) async => const <String, dynamic>{};

  @override
  Future<void> updateQuote(
    AppSession session,
    String symbol,
    Quote quote,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteQuote(AppSession session, String quoteId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchMarketDataProviders(
    AppSession session,
  ) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMarketDataProviderSettings(
    AppSession session,
  ) async => const <Map<String, dynamic>>[];

  @override
  Future<void> updateMarketDataProviderSettings(
    AppSession session, {
    required String providerId,
    required int priority,
    required bool enabled,
  }) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchExchanges(AppSession session) async =>
      const <Map<String, dynamic>>[];

  // ---- Assets CRUD ----

  @override
  Future<Asset> createAsset(AppSession session, Map<String, dynamic> data) =>
      throw UnimplementedError();

  @override
  Future<Asset> updateAssetProfile(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<Asset> updateAssetQuoteMode(
    AppSession session,
    String id,
    String quoteMode,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteAsset(AppSession session, String id) =>
      throw UnimplementedError();

  // ---- Contribution limits ----

  @override
  Future<List<ContributionLimit>> fetchContributionLimits(
    AppSession session,
  ) async => const <ContributionLimit>[];

  @override
  Future<ContributionLimit> createContributionLimit(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<ContributionLimit> updateContributionLimit(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteContributionLimit(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<DepositsCalculation> fetchContributionLimitDeposits(
    AppSession session,
    String id,
  ) => throw UnimplementedError();

  // ---- Taxonomies ----

  @override
  Future<List<Taxonomy>> fetchTaxonomies(AppSession session) async =>
      const <Taxonomy>[];

  @override
  Future<TaxonomyWithCategories?> fetchTaxonomy(
    AppSession session,
    String id,
  ) async => null;

  @override
  Future<Taxonomy> createTaxonomy(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<Taxonomy> updateTaxonomy(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteTaxonomy(AppSession session, String id) =>
      throw UnimplementedError();

  @override
  Future<Category> createCategory(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<Category> updateCategory(
    AppSession session,
    Map<String, dynamic> data,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(
    AppSession session, {
    required String taxonomyId,
    required String categoryId,
  }) => throw UnimplementedError();

  // ---- Health ----

  @override
  Future<HealthStatus> fetchHealthStatus(
    AppSession session, {
    String? timezone,
  }) async => const HealthStatus(
        overallSeverity: 'INFO',
        issueCounts: <String, int>{},
        issues: <HealthIssue>[],
        checkedAt: '',
        isStale: false,
      );

  @override
  Future<HealthStatus> runHealthChecks(
    AppSession session, {
    String? timezone,
  }) async => const HealthStatus(
        overallSeverity: 'INFO',
        issueCounts: <String, int>{},
        issues: <HealthIssue>[],
        checkedAt: '',
        isStale: false,
      );

  @override
  Future<void> dismissHealthIssue(
    AppSession session, {
    required String issueId,
    required String dataHash,
  }) => throw UnimplementedError();

  @override
  Future<void> restoreHealthIssue(AppSession session, String issueId) =>
      throw UnimplementedError();
}
