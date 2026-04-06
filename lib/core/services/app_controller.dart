import 'package:flutter/foundation.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
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
  AppController({
    required SessionStorage storage,
    required WealthfolioApi api,
  }) : _storage = storage,
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
    if (storedSession == null) {
      _stage = AppStage.unauthenticated;
      notifyListeners();
      return;
    }

    _session = storedSession;
    _stage = AppStage.authenticated;
    _loadingAccounts = true;
    _loadingHoldings = true;
    notifyListeners();

    try {
      // Validate the restored session and load initial data.
      await _api.getAuthStatus(storedSession);
      await Future.wait<void>(<Future<void>>[
        _fetchAccounts(storedSession),
        _fetchHoldings(storedSession),
        _loadBaseCurrency(storedSession),
      ]);
    } on Exception {
      _stage = AppStage.unauthenticated;
      _session = null;
      _accounts = const <Account>[];
      _holdings = const <Holding>[];
      _loadingAccounts = false;
      _loadingHoldings = false;
      await _storage.clearSession();
      _errorMessage = 'Saved session expired. Sign in again.';
      notifyListeners();
    }
  }

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
      _stage = AppStage.authenticated;
      await _storage.saveSession(nextSession);

      await Future.wait<void>(<Future<void>>[
        _fetchAccounts(nextSession),
        _fetchHoldings(nextSession),
        _loadBaseCurrency(nextSession),
      ]);
    });
  }

  Future<void> signOut() async {
    _session = null;
    _accounts = const <Account>[];
    _holdings = const <Holding>[];
    _errorMessage = null;
    _loadingAccounts = false;
    _loadingHoldings = false;
    _lastRefreshedAt = null;
    _baseCurrency = 'USD';
    _stage = AppStage.unauthenticated;
    await _storage.clearSession();
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
      await _runBusyAction(() => _fetchHoldings(session));
    } else {
      await _fetchHoldings(session);
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

  Future<void> _fetchHoldings(AppSession session) async {
    _loadingHoldings = true;
    notifyListeners();

    try {
      _holdings = await _api.fetchHoldings(session);
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
