import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/activity.dart';
import 'package:wealthfolio_flutter/core/models/asset.dart';
import 'package:wealthfolio_flutter/core/models/exchange_rate.dart';
import 'package:wealthfolio_flutter/core/models/goal.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';
import 'package:wealthfolio_flutter/core/models/settings.dart';
import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

import 'native_adapter_helper.dart'
    if (dart.library.js_interop) 'native_adapter_helper_web.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract class WealthfolioApi {
  // Auth
  Future<void> verifyServer(String serverUrl);
  Future<AppSession> signIn({
    required String serverUrl,
    required String username,
    required String password,
  });
  Future<Map<String, dynamic>> getAuthStatus(AppSession session);

  // Accounts
  Future<List<Account>> fetchAccounts(
    AppSession session, {
    bool includeArchived = false,
  });
  Future<Account> createAccount(AppSession session, Map<String, dynamic> data);
  Future<Account> updateAccount(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  );
  Future<void> deleteAccount(AppSession session, String id);

  // Holdings
  Future<List<Holding>> fetchHoldings(AppSession session, {String? accountId});
  Future<Holding?> fetchHolding(
    AppSession session, {
    required String accountId,
    required String assetId,
  });
  Future<List<Holding>> fetchHoldingsByAsset(
    AppSession session,
    String assetId,
  );

  // Activities
  Future<ActivitySearchResponse> searchActivities(
    AppSession session, {
    int page = 1,
    int pageSize = 50,
    String? accountId,
    String? activityType,
    String? assetKeyword,
    String? sort,
  });
  Future<Activity> createActivity(
    AppSession session,
    Map<String, dynamic> data,
  );
  Future<Activity> updateActivity(
    AppSession session,
    Map<String, dynamic> data,
  );
  Future<void> deleteActivity(AppSession session, String id);

  // Performance
  Future<List<Map<String, dynamic>>> fetchSimplePerformance(
    AppSession session,
    List<String> accountIds,
  );
  Future<Map<String, dynamic>> fetchPerformanceHistory(
    AppSession session, {
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
  });
  Future<Map<String, dynamic>> fetchPerformanceSummary(
    AppSession session, {
    required String itemType,
    required String itemId,
  });

  // Net Worth
  Future<Map<String, dynamic>> fetchNetWorth(
    AppSession session, {
    String? date,
  });
  Future<List<Map<String, dynamic>>> fetchNetWorthHistory(
    AppSession session, {
    required String startDate,
    required String endDate,
  });

  // Settings
  Future<Settings> fetchSettings(AppSession session);
  Future<Settings> updateSettings(
    AppSession session,
    Map<String, dynamic> data,
  );

  // Portfolio
  Future<void> updatePortfolio(AppSession session);
  Future<void> recalculatePortfolio(AppSession session);

  // Goals
  Future<List<Goal>> fetchGoals(AppSession session);
  Future<Goal> createGoal(AppSession session, Map<String, dynamic> data);
  Future<Goal> updateGoal(AppSession session, Map<String, dynamic> data);
  Future<void> deleteGoal(AppSession session, String id);

  // Exchange Rates
  Future<List<ExchangeRate>> fetchExchangeRates(AppSession session);
  Future<ExchangeRate> addExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  );
  Future<ExchangeRate> updateExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  );
  Future<void> deleteExchangeRate(AppSession session, String id);

  // Income
  Future<Map<String, dynamic>> fetchIncomeSummary(
    AppSession session, {
    String? accountId,
  });

  // Market Data
  Future<List<Map<String, dynamic>>> searchSymbol(
    AppSession session,
    String query,
  );
  Future<void> syncMarketData(AppSession session);

  // Assets
  Future<List<Asset>> fetchAssets(AppSession session);
  Future<Asset> fetchAssetProfile(AppSession session, String assetId);

  // Allocations
  Future<Map<String, dynamic>> fetchAllocations(
    AppSession session, {
    String? accountId,
  });
  Future<Map<String, dynamic>> fetchAllocationHoldings(
    AppSession session, {
    required String accountId,
    required String taxonomyId,
    required String categoryId,
  });
}

// ---------------------------------------------------------------------------
// Concrete network implementation
// ---------------------------------------------------------------------------

class NetworkWealthfolioApi implements WealthfolioApi {
  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  @override
  Future<void> verifyServer(String serverUrl) async {
    final url = _normalizeUrl(serverUrl);
    final dio = _createDio(url, token: null, useApiPrefix: false);
    try {
      final response = await dio.get<dynamic>('/healthz');
      final status = response.statusCode ?? 0;
      if (status >= 500 || status == 0) {
        throw const WealthfolioException(
          'The Wealthfolio server did not respond successfully.',
        );
      }
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<AppSession> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _normalizeUrl(serverUrl);
    final dio = _createDio(url, token: null);
    try {
      final response = await dio.post<dynamic>(
        '/auth/login',
        data: <String, String>{'username': username, 'password': password},
      );
      _throwIfRequestFailed(response);
      final body = parseMap(response.data);
      final token = body['token']?.toString();
      return AppSession(
        serverUrl: url,
        token: token,
        username: username.trim(),
      );
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthStatus(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>('/auth/status');
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------------

  @override
  Future<List<Account>> fetchAccounts(
    AppSession session, {
    bool includeArchived = false,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/accounts',
        queryParameters: includeArchived
            ? const <String, dynamic>{'include_archived': true}
            : null,
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => Account.fromJson(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Account> createAccount(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>('/accounts', data: data);
      _throwIfRequestFailed(response);
      return Account.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Account> updateAccount(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>(
        '/accounts/${Uri.encodeComponent(id)}',
        data: data,
      );
      _throwIfRequestFailed(response);
      return Account.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> deleteAccount(AppSession session, String id) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.delete<dynamic>(
        '/accounts/${Uri.encodeComponent(id)}',
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Holdings
  // -------------------------------------------------------------------------

  @override
  Future<List<Holding>> fetchHoldings(
    AppSession session, {
    String? accountId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/holdings',
        queryParameters: accountId != null
            ? <String, dynamic>{'account_id': accountId}
            : null,
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => Holding.fromJson(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Holding?> fetchHolding(
    AppSession session, {
    required String accountId,
    required String assetId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/holdings/item',
        queryParameters: <String, dynamic>{
          'account_id': accountId,
          'asset_id': assetId,
        },
      );
      if ((response.statusCode ?? 500) == 404) {
        return null;
      }
      _throwIfRequestFailed(response);
      return Holding.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<List<Holding>> fetchHoldingsByAsset(
    AppSession session,
    String assetId,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/holdings/by-asset',
        queryParameters: <String, dynamic>{'asset_id': assetId},
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => Holding.fromJson(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Activities
  // -------------------------------------------------------------------------

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
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final body = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'account_id': ?accountId,
        'activity_type': ?activityType,
        'asset_keyword': ?assetKeyword,
        'sort': ?sort,
      };
      final response = await dio.post<dynamic>(
        '/activities/search',
        data: body,
      );
      _throwIfRequestFailed(response);
      return ActivitySearchResponse.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Activity> createActivity(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>('/activities', data: data);
      _throwIfRequestFailed(response);
      return Activity.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Activity> updateActivity(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>('/activities', data: data);
      _throwIfRequestFailed(response);
      return Activity.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> deleteActivity(AppSession session, String id) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.delete<dynamic>(
        '/activities',
        queryParameters: <String, dynamic>{'id': id},
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Performance
  // -------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> fetchSimplePerformance(
    AppSession session,
    List<String> accountIds,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>(
        '/performance/accounts/simple',
        data: <String, dynamic>{'account_ids': accountIds},
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => parseMap(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceHistory(
    AppSession session, {
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final body = <String, dynamic>{
        'item_type': itemType,
        'item_id': itemId,
        'start_date': ?startDate,
        'end_date': ?endDate,
      };
      final response = await dio.post<dynamic>(
        '/performance/history',
        data: body,
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceSummary(
    AppSession session, {
    required String itemType,
    required String itemId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>(
        '/performance/summary',
        data: <String, dynamic>{'item_type': itemType, 'item_id': itemId},
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Net Worth
  // -------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> fetchNetWorth(
    AppSession session, {
    String? date,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/net-worth',
        queryParameters: date != null ? <String, dynamic>{'date': date} : null,
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNetWorthHistory(
    AppSession session, {
    required String startDate,
    required String endDate,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/net-worth/history',
        queryParameters: <String, dynamic>{
          'start_date': startDate,
          'end_date': endDate,
        },
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => parseMap(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  @override
  Future<Settings> fetchSettings(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>('/settings');
      _throwIfRequestFailed(response);
      return Settings.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Settings> updateSettings(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>('/settings', data: data);
      _throwIfRequestFailed(response);
      return Settings.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Portfolio
  // -------------------------------------------------------------------------

  @override
  Future<void> updatePortfolio(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>(
        '/portfolio/update',
        data: const <String, dynamic>{},
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> recalculatePortfolio(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>(
        '/portfolio/recalculate',
        data: const <String, dynamic>{},
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Goals
  // -------------------------------------------------------------------------

  @override
  Future<List<Goal>> fetchGoals(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>('/goals');
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => Goal.fromJson(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Goal> createGoal(AppSession session, Map<String, dynamic> data) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>('/goals', data: data);
      _throwIfRequestFailed(response);
      return Goal.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Goal> updateGoal(AppSession session, Map<String, dynamic> data) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>('/goals', data: data);
      _throwIfRequestFailed(response);
      return Goal.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> deleteGoal(AppSession session, String id) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.delete<dynamic>(
        '/goals/${Uri.encodeComponent(id)}',
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Exchange Rates
  // -------------------------------------------------------------------------

  @override
  Future<List<ExchangeRate>> fetchExchangeRates(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>('/exchange-rates/latest');
      _throwIfRequestFailed(response);
      return parseList(response.data)
          .map((dynamic item) => ExchangeRate.fromJson(item))
          .toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<ExchangeRate> addExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>('/exchange-rates', data: data);
      _throwIfRequestFailed(response);
      return ExchangeRate.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<ExchangeRate> updateExchangeRate(
    AppSession session,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>('/exchange-rates', data: data);
      _throwIfRequestFailed(response);
      return ExchangeRate.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> deleteExchangeRate(AppSession session, String id) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.delete<dynamic>(
        '/exchange-rates/${Uri.encodeComponent(id)}',
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Income
  // -------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> fetchIncomeSummary(
    AppSession session, {
    String? accountId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/income/summary',
        queryParameters: accountId != null
            ? <String, dynamic>{'account_id': accountId}
            : null,
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Market Data
  // -------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> searchSymbol(
    AppSession session,
    String query,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/market-data/search',
        queryParameters: <String, dynamic>{'query': query},
      );
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => parseMap(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<void> syncMarketData(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.post<dynamic>(
        '/market-data/sync',
        data: const <String, dynamic>{},
      );
      _throwIfRequestFailed(response);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Assets
  // -------------------------------------------------------------------------

  @override
  Future<List<Asset>> fetchAssets(AppSession session) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>('/assets');
      _throwIfRequestFailed(response);
      return parseList(
        response.data,
      ).map((dynamic item) => Asset.fromJson(item)).toList(growable: false);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Asset> fetchAssetProfile(AppSession session, String assetId) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/assets/profile',
        queryParameters: <String, dynamic>{'asset_id': assetId},
      );
      _throwIfRequestFailed(response);
      return Asset.fromJson(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Allocations
  // -------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> fetchAllocations(
    AppSession session, {
    String? accountId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/allocations',
        queryParameters: accountId != null
            ? <String, dynamic>{'account_id': accountId}
            : null,
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchAllocationHoldings(
    AppSession session, {
    required String accountId,
    required String taxonomyId,
    required String categoryId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/allocations/holdings',
        queryParameters: <String, dynamic>{
          'account_id': accountId,
          'taxonomy_id': taxonomyId,
          'category_id': categoryId,
        },
      );
      _throwIfRequestFailed(response);
      return parseMap(response.data);
    } on DioException catch (error) {
      throw WealthfolioException(_formatDioError(error));
    } finally {
      dio.close(force: true);
    }
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Dio _createDio(
    String serverUrl, {
    required String? token,
    bool useApiPrefix = true,
  }) {
    final base = useApiPrefix
        ? '${_normalizeUrl(serverUrl)}/api/v1'
        : _normalizeUrl(serverUrl);

    final dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        validateStatus: (_) => true,
        contentType: 'application/json',
      ),
    );

    dio.httpClientAdapter = createPlatformAdapter();
    dio.options.headers['User-Agent'] = 'WealthfolioFlutter/1.0';
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    return dio;
  }

  void _throwIfRequestFailed(Response<dynamic> response) {
    final status = response.statusCode ?? 500;
    if (status >= 400) {
      final body = parseMap(response.data);
      final message =
          _extractErrorMessage(body) ?? 'Request failed with HTTP $status.';
      _captureHttpFailure(
        response.requestOptions,
        statusCode: status,
        message: message,
        responseBody: body.isEmpty ? response.data : body,
      );
      throw WealthfolioException(message);
    }
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class WealthfolioException implements Exception {
  const WealthfolioException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Private top-level helpers
// ---------------------------------------------------------------------------

String _normalizeUrl(String serverUrl) {
  return serverUrl.trim().replaceFirst(RegExp(r'/$'), '');
}

String _formatDioError(DioException error) {
  final responseBody = parseMap(error.response?.data);
  _captureHttpFailure(
    error.requestOptions,
    statusCode: error.response?.statusCode,
    message: error.message?.trim() ?? 'Network request failed.',
    responseBody: responseBody.isEmpty ? error.response?.data : responseBody,
    exception: error,
  );
  final apiMessage = _extractErrorMessage(responseBody);
  if (apiMessage != null) {
    return apiMessage;
  }

  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    return message;
  }

  return 'Network request failed.';
}

void _captureHttpFailure(
  RequestOptions requestOptions, {
  required String message,
  int? statusCode,
  dynamic responseBody,
  Object? exception,
}) {
  final sanitizedHeaders = _sanitizeValue(requestOptions.headers);
  final sanitizedRequestData = _sanitizeValue(requestOptions.data);
  final sanitizedResponseBody = _sanitizeValue(responseBody);
  final apiContext = <String, dynamic>{
    'base_url': requestOptions.baseUrl,
    'method': requestOptions.method,
    'path': requestOptions.path,
    'uri': requestOptions.uri.toString(),
    'query_parameters': requestOptions.queryParameters,
    'request_headers': sanitizedHeaders,
    'request_data': sanitizedRequestData,
  };
  if (sanitizedResponseBody != null) {
    apiContext['response_body'] = sanitizedResponseBody;
  }

  Sentry.configureScope((scope) {
    scope.setTag('api.base_url', requestOptions.baseUrl);
    scope.setTag('api.method', requestOptions.method);
    scope.setContexts('api', apiContext);
    if (statusCode != null) {
      scope.setTag('http.status_code', statusCode.toString());
      scope.level = statusCode >= 500 ? SentryLevel.error : SentryLevel.warning;
    }
  });

  if (exception != null) {
    Sentry.captureException(
      exception,
      withScope: (scope) {
        scope.fingerprint = <String>[
          'wealthfolio-api',
          requestOptions.method,
          requestOptions.path,
          if (statusCode != null) statusCode.toString(),
        ];
      },
    );
    return;
  }

  Sentry.captureMessage(
    message,
    withScope: (scope) {
      scope.fingerprint = <String>[
        'wealthfolio-api',
        requestOptions.method,
        requestOptions.path,
        if (statusCode != null) statusCode.toString(),
      ];
    },
  );
}

dynamic _sanitizeValue(dynamic value) {
  if (value is Map) {
    return value.map<dynamic, dynamic>((dynamic key, dynamic nestedValue) {
      final normalizedKey = key.toString().toLowerCase();
      if (_isSensitiveKey(normalizedKey)) {
        return MapEntry<dynamic, dynamic>(key, '[redacted]');
      }
      return MapEntry<dynamic, dynamic>(key, _sanitizeValue(nestedValue));
    });
  }

  if (value is Iterable) {
    return value.map<dynamic>(_sanitizeValue).toList(growable: false);
  }

  return value;
}

bool _isSensitiveKey(String key) {
  return key.contains('authorization') ||
      key.contains('password') ||
      key.contains('token') ||
      key.contains('secret');
}

String? _extractErrorMessage(Map<String, dynamic> body) {
  final candidates = <String?>[
    body['error']?.toString(),
    body['message']?.toString(),
    body['detail']?.toString(),
  ];

  for (final field in candidates) {
    if (field != null && field.trim().isNotEmpty) {
      return field.trim();
    }
  }

  return null;
}
