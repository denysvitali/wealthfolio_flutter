import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/models/goal.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/models/income_summary.dart';
import 'package:wealthfolio_flutter/core/models/net_worth.dart';
import 'package:wealthfolio_flutter/core/models/performance.dart';
import 'package:wealthfolio_flutter/core/models/portfolio_allocation.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';
import 'package:wealthfolio_flutter/core/models/settings.dart';

import '../api/wealthfolio_api.dart';
import 'session_storage.dart';

// ---------------------------------------------------------------------------
// App lifecycle stage
// ---------------------------------------------------------------------------

enum AppStage { booting, unauthenticated, authenticated }

// ---------------------------------------------------------------------------
// AppController
// ---------------------------------------------------------------------------

class AppController extends ChangeNotifier {
  AppController({required SessionStorage storage, required WealthfolioApi api})
    : _storage = storage,
      _api = api;

  final SessionStorage _storage;
  final WealthfolioApi _api;

  // --- Stage & status -------------------------------------------------------

  AppStage _stage = AppStage.booting;
  AppStage get stage => _stage;

  bool _busy = false;
  bool get busy => _busy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Session --------------------------------------------------------------

  AppSession? _session;
  AppSession? get session => _session;

  // --- Data -----------------------------------------------------------------

  List<Account> _accounts = const <Account>[];
  List<Account> get accounts => _accounts;

  List<Holding> _holdings = const <Holding>[];
  List<Holding> get holdings => _holdings;

  DateTime? _lastRefreshedAt;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  bool _loadingAccounts = false;
  bool get loadingAccounts => _loadingAccounts;

  bool _loadingHoldings = false;
  bool get loadingHoldings => _loadingHoldings;

  String _baseCurrency = 'USD';
  String get baseCurrency => _baseCurrency;

  // --- Initialization -------------------------------------------------------

  Future<void>? _bootstrapFuture;
  Future<void> initialize() {
    return _bootstrapFuture ??= _initializeImpl();
  }

  Future<void> _initializeImpl() async {
    final storedSession = await _storage.loadSession();
    var activeSession = storedSession;

    if (activeSession != null) {
      _session = activeSession;
      _setSentryUser(activeSession);
      _stage = AppStage.authenticated;
      _loadingAccounts = true;
      _loadingHoldings = true;
      notifyListeners();

      try {
        await _api.getAuthStatus(activeSession);
      } on WealthfolioException catch (e) {
        if (_isAuthError(e)) {
          activeSession = await _restoreExpiredSession();
          if (activeSession == null) {
            await _clearSession();
            return;
          }
          _session = activeSession;
          _setSentryUser(activeSession);
        }
      }
    } else {
      // No stored session — try stored credentials (first launch after the
      // token couldn't be persisted, e.g. on Flutter web where Set-Cookie is
      // stripped, or after a manual storage wipe that spared the credentials).
      activeSession = await _restoreExpiredSession();
      if (activeSession == null) {
        _stage = AppStage.unauthenticated;
        notifyListeners();
        return;
      }
      _session = activeSession;
      _setSentryUser(activeSession);
      _stage = AppStage.authenticated;
      _loadingAccounts = true;
      _loadingHoldings = true;
      notifyListeners();
    }

    // Load accounts first — holdings require accountId.
    try {
      await _fetchAccounts(activeSession);
    } on WealthfolioException catch (e) {
      if (_isAuthError(e)) {
        await _clearSession();
        return;
      }
      _loadingHoldings = false;
      notifyListeners();
      return;
    }

    // Fetch holdings per-account and base currency in parallel.
    await Future.wait<void>(<Future<void>>[
      _fetchHoldingsForAccounts(activeSession, _accounts),
      _loadBaseCurrency(activeSession),
    ]);
  }

  void _setSentryUser(AppSession session) {
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          username: session.username,
          data: <String, dynamic>{'server_url': session.serverUrl},
        ),
      );
    });
  }

  /// Returns true if the exception is an authentication/authorization failure
  /// that warrants clearing the stored session.
  bool _isAuthError(WealthfolioException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('unauthorized') ||
        msg.contains('401') ||
        msg.contains('forbidden') ||
        msg.contains('authentication');
  }

  Future<void> _clearSession() async {
    _stage = AppStage.unauthenticated;
    _session = null;
    _accounts = const <Account>[];
    _holdings = const <Holding>[];
    _loadingAccounts = false;
    _loadingHoldings = false;
    _errorMessage = 'Saved session expired. Sign in again.';
    await _storage.clearSession();
    notifyListeners();
  }

  Future<AppSession?> _restoreExpiredSession() async {
    final credentials = await _storage.loadCredentials();
    if (credentials == null) {
      return null;
    }

    try {
      final refreshedSession = await _api.signIn(
        serverUrl: credentials.serverUrl,
        username: credentials.username,
        password: credentials.password,
      );
      await _storage.saveSession(refreshedSession);
      return refreshedSession;
    } on WealthfolioException {
      // Stored credentials no longer valid — caller will surface unauthenticated.
      return null;
    }
  }

  /// Loads the credentials previously persisted on sign-in, used by the
  /// connect screen to pre-fill the server URL and username fields.
  Future<StoredCredentials?> loadSavedCredentials() =>
      _storage.loadCredentials();

  /// Loads the last server URL the user successfully signed in to.
  Future<String?> loadLastServerUrl() => _storage.loadLastServerUrl();

  // --- Auth -----------------------------------------------------------------

  Future<void> connectToServer(String serverUrl) async {
    await _runBusyAction(() async {
      await _api.verifyServer(serverUrl.trim());
    });
  }

  Future<void> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    await _runBusyAction(() async {
      final normalizedUrl = serverUrl.trim();
      await _storage.saveLastServerUrl(normalizedUrl);

      final nextSession = await _api.signIn(
        serverUrl: normalizedUrl,
        username: username.trim(),
        password: password,
      );

      _session = nextSession;
      _setSentryUser(nextSession);
      _stage = AppStage.authenticated;
      await _storage.saveCredentials(
        serverUrl: normalizedUrl,
        username: username.trim(),
        password: password,
      );
      await _storage.saveSession(nextSession);

      // Fetch accounts first — holdings require accountId.
      await _fetchAccounts(nextSession);
      await Future.wait<void>(<Future<void>>[
        _fetchHoldingsForAccounts(nextSession, _accounts),
        _loadBaseCurrency(nextSession),
      ]);
    });
  }

  Future<void> signOut() async {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
    _session = null;
    _accounts = const <Account>[];
    _holdings = const <Holding>[];
    _errorMessage = null;
    _loadingAccounts = false;
    _loadingHoldings = false;
    _lastRefreshedAt = null;
    _baseCurrency = 'USD';
    _stage = AppStage.unauthenticated;
    await _storage.clearCredentials();
    notifyListeners();
  }

  // --- Accounts -------------------------------------------------------------

  Future<void> refreshAccounts({bool showSpinner = true}) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    if (showSpinner) {
      await _runBusyAction(() => _fetchAccounts(session));
    } else {
      await _fetchAccounts(session);
    }
  }

  Future<Account> createAccount(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    late Account created;
    await _runBusyAction(() async {
      created = await _api.createAccount(session, data);
      await _fetchAccounts(session);
    });
    return created;
  }

  Future<Account> updateAccount(String id, Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    late Account updated;
    await _runBusyAction(() async {
      updated = await _api.updateAccount(session, id, data);
      await _fetchAccounts(session);
    });
    return updated;
  }

  Future<void> deleteAccount(String id) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    await _runBusyAction(() async {
      await _api.deleteAccount(session, id);
      await _fetchAccounts(session);
    });
  }

  // --- Holdings -------------------------------------------------------------

  Future<void> refreshHoldings({bool showSpinner = true}) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    if (showSpinner) {
      await _runBusyAction(() => _fetchHoldingsForAccounts(session, _accounts));
    } else {
      await _fetchHoldingsForAccounts(session, _accounts);
    }
  }

  // --- Activities -----------------------------------------------------------

  Future<ActivitySearchResponse> searchActivities({
    int page = 1,
    int pageSize = 50,
    String? accountId,
    String? activityType,
    String? assetKeyword,
    String? sort,
  }) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.searchActivities(
      session,
      page: page,
      pageSize: pageSize,
      accountId: accountId,
      activityType: activityType,
      assetKeyword: assetKeyword,
      sort: sort,
    );
  }

  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.createActivity(session, data);
  }

  Future<Activity> updateActivity(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.updateActivity(session, data);
  }

  Future<void> deleteActivity(String id) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    await _api.deleteActivity(session, id);
  }

  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.searchSymbol(session, query);
  }

  // --- Goals ----------------------------------------------------------------

  Future<List<Goal>> fetchGoals() async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.fetchGoals(session);
  }

  Future<Goal> createGoal(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.createGoal(session, data);
  }

  Future<Goal> updateGoal(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.updateGoal(session, data);
  }

  Future<void> deleteGoal(String id) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    await _api.deleteGoal(session, id);
  }

  // --- Income ---------------------------------------------------------------

  Future<IncomeSummary> fetchIncomeSummary({String? accountId}) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final raw = await _api.fetchIncomeSummary(session, accountId: accountId);
    return IncomeSummary.fromJson(raw);
  }

  // --- Net Worth ------------------------------------------------------------

  Future<NetWorthResponse> fetchNetWorth({String? date}) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final raw = await _api.fetchNetWorth(session, date: date);
    return NetWorthResponse.fromJson(raw);
  }

  Future<List<NetWorthHistoryPoint>> fetchNetWorthHistory({
    required String startDate,
    required String endDate,
  }) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final rawList = await _api.fetchNetWorthHistory(
      session,
      startDate: startDate,
      endDate: endDate,
    );
    return rawList.map(NetWorthHistoryPoint.fromJson).toList(growable: false);
  }

  Future<List<PerformanceHistory>> fetchPerformanceHistory({
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
  }) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final raw = await _api.fetchPerformanceHistory(
      session,
      itemType: itemType,
      itemId: itemId,
      startDate: startDate,
      endDate: endDate,
    );
    final items = switch (raw['data']) {
      final List<dynamic> list => list,
      _ =>
        raw['history'] is List
            ? raw['history'] as List<dynamic>
            : const <dynamic>[],
    };
    return items.map(PerformanceHistory.fromJson).toList(growable: false);
  }

  Future<PerformanceMetrics> fetchPerformanceSummary({
    required String itemType,
    required String itemId,
  }) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final raw = await _api.fetchPerformanceSummary(
      session,
      itemType: itemType,
      itemId: itemId,
    );
    return PerformanceMetrics.fromJson(raw);
  }

  // --- Allocations ----------------------------------------------------------

  Future<List<PortfolioAllocation>> fetchAllocations({
    String? accountId,
  }) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    final raw = await _api.fetchAllocations(session, accountId: accountId);
    // The API returns a map with allocation arrays per category type.
    // Flatten all allocation entries across taxonomy groups.
    final allocations = <PortfolioAllocation>[];
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          allocations.add(PortfolioAllocation.fromJson(item));
        }
      } else if (value is Map) {
        // Some APIs nest under a key like 'allocations' or 'categories'.
        final nested = value['allocations'] ?? value['categories'];
        if (nested is List) {
          for (final item in nested) {
            allocations.add(PortfolioAllocation.fromJson(item));
          }
        }
      }
    }
    return allocations;
  }

  // --- Settings -------------------------------------------------------------

  Future<Settings> fetchSettings() async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }
    return _api.fetchSettings(session);
  }

  Future<Settings> updateSettings(Map<String, dynamic> data) async {
    final session = _session;
    if (session == null) {
      throw const WealthfolioException('Not signed in.');
    }

    late Settings updated;
    await _runBusyAction(() async {
      updated = await _api.updateSettings(session, data);
      _baseCurrency = updated.baseCurrency;
    });
    return updated;
  }

  // --- Error management -----------------------------------------------------

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<void> _runBusyAction(Future<void> Function() action) async {
    if (_busy) {
      throw const WealthfolioException('Another action is in progress.');
    }
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on WealthfolioException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } on Exception {
      _errorMessage = 'Something went wrong while contacting Wealthfolio.';
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAccounts(AppSession session) async {
    _loadingAccounts = true;
    notifyListeners();

    try {
      _accounts = await _api.fetchAccounts(session);
      _lastRefreshedAt = DateTime.now();
      _errorMessage = null;
    } on WealthfolioException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } on Exception {
      _errorMessage = 'Failed to load accounts.';
      rethrow;
    } finally {
      _loadingAccounts = false;
      notifyListeners();
    }
  }

  Future<void> _fetchHoldingsForAccounts(
    AppSession session,
    List<Account> accounts,
  ) async {
    _loadingHoldings = true;
    notifyListeners();

    try {
      final allHoldings = <Holding>[];
      await Future.wait<void>(
        accounts.map((account) async {
          final holdings = await _api.fetchHoldings(
            session,
            accountId: account.id,
          );
          allHoldings.addAll(holdings);
        }),
      );
      _holdings = allHoldings;
      _lastRefreshedAt = DateTime.now();
      _errorMessage = null;
    } on WealthfolioException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } on Exception {
      _errorMessage = 'Failed to load holdings.';
      rethrow;
    } finally {
      _loadingHoldings = false;
      notifyListeners();
    }
  }

  Future<void> _loadBaseCurrency(AppSession session) async {
    try {
      final settings = await _api.fetchSettings(session);
      _baseCurrency = settings.baseCurrency;
      notifyListeners();
    } on Exception {
      // Non-fatal: keep the default.
    }
  }
}
