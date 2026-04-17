import 'dart:convert';

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
  Future<List<Holding>> fetchHoldings(
    AppSession session, {
    required String accountId,
  });
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
    String? trackingMode,
  });
  Future<Map<String, dynamic>> fetchPerformanceSummary(
    AppSession session, {
    required String itemType,
    required String itemId,
    String? startDate,
    String? endDate,
    String? trackingMode,
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
  Future<List<dynamic>> fetchIncomeSummary(
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
        data: <String, String>{'password': password},
      );
      _throwIfRequestFailed(response);
      final body = parseMap(response.data);
      // The Wealthfolio backend returns the JWT via a Set-Cookie header
      // (wf_session=<token>), not in the response body. The body only
      // contains {"authenticated": true, "expiresIn": <seconds>}.
      final token = body['token']?.toString() ?? _extractSessionToken(response);
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

  /// Extracts the JWT from the `wf_session` Set-Cookie header.
  ///
  /// The Wealthfolio backend sets an HttpOnly session cookie named `wf_session`
  /// containing the signed JWT. We extract the token value to use as a Bearer
  /// token in subsequent requests (the backend accepts both Bearer tokens and
  /// cookies via its `extract_token` function).
  static String? _extractSessionToken(Response<dynamic> response) {
    final cookies = response.headers['set-cookie'];
    if (cookies == null) return null;
    for (final cookie in cookies) {
      // Format: wf_session=TOKEN; HttpOnly; SameSite=Lax; Path=/api; Max-Age=3600[; Secure]
      final parts = cookie.split(';');
      if (parts.isEmpty) continue;
      final nameValue = parts[0].trim();
      if (nameValue.startsWith('wf_session=')) {
        final token = nameValue.substring('wf_session='.length).trim();
        if (token.isNotEmpty) return token;
      }
    }
    return null;
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
            ? const <String, dynamic>{'includeArchived': true}
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
      final response = await dio.post<dynamic>(
        '/accounts',
        data: normalizeAccountPayloadForRest(data),
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
  Future<Account> updateAccount(
    AppSession session,
    String id,
    Map<String, dynamic> data,
  ) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.put<dynamic>(
        '/accounts/${Uri.encodeComponent(id)}',
        data: normalizeAccountPayloadForRest(data, isUpdate: true),
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
    required String accountId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/holdings',
        queryParameters: <String, dynamic>{'accountId': accountId},
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
          'accountId': accountId,
          'assetId': assetId,
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
        queryParameters: <String, dynamic>{'assetId': assetId},
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
        'pageSize': pageSize,
        'accountIdFilter': ?accountId,
        'activityTypeFilter': ?activityType,
        'assetIdKeyword': ?assetKeyword,
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
      final response = await dio.post<dynamic>(
        '/activities',
        data: normalizeActivityPayloadForRest(data),
      );
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
      final response = await dio.put<dynamic>(
        '/activities',
        data: normalizeActivityPayloadForRest(data, isUpdate: true),
      );
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
        '/activities/${Uri.encodeComponent(id)}',
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
        data: <String, dynamic>{'accountIds': accountIds},
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
    String? trackingMode,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final body = <String, dynamic>{
        'itemType': itemType,
        'itemId': itemId,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'trackingMode': ?trackingMode,
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
    String? startDate,
    String? endDate,
    String? trackingMode,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final body = <String, dynamic>{
        'itemType': itemType,
        'itemId': itemId,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'trackingMode': ?trackingMode,
      };
      final response = await dio.post<dynamic>(
        '/performance/summary',
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
          'startDate': startDate,
          'endDate': endDate,
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
  Future<List<dynamic>> fetchIncomeSummary(
    AppSession session, {
    String? accountId,
  }) async {
    final dio = _createDio(session.serverUrl, token: session.token);
    try {
      final response = await dio.get<dynamic>(
        '/income/summary',
        queryParameters: accountId != null
            ? <String, dynamic>{'accountId': accountId}
            : null,
      );
      _throwIfRequestFailed(response);
      return parseList(response.data);
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
        queryParameters: <String, dynamic>{'assetId': assetId},
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
            ? <String, dynamic>{'accountId': accountId}
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
          'accountId': accountId,
          'taxonomyId': taxonomyId,
          'categoryId': categoryId,
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

Map<String, dynamic> normalizeAccountPayloadForRest(
  Map<String, dynamic> data, {
  bool isUpdate = false,
}) {
  final payload = <String, dynamic>{
    if ((data['id'] ?? '').toString().isNotEmpty) 'id': data['id'],
    'name': (data['name'] ?? '').toString().trim(),
    'accountType': (data['accountType'] ?? data['account_type'] ?? '')
        .toString()
        .trim()
        .toUpperCase(),
    'group': _nullableTrimmedString(data['group']),
    if (!isUpdate)
      'currency': (data['currency'] ?? '').toString().trim().toUpperCase(),
    'isDefault': _coerceBool(data['isDefault'] ?? data['is_default']),
    'isActive': _coerceBool(
      data['isActive'] ?? data['is_active'],
      fallback: true,
    ),
    if (!isUpdate)
      'isArchived': _coerceBool(data['isArchived'] ?? data['is_archived']),
    if (isUpdate)
      'isArchived':
          data.containsKey('isArchived') || data.containsKey('is_archived')
          ? _coerceBool(data['isArchived'] ?? data['is_archived'])
          : null,
    if (!isUpdate)
      'trackingMode': _normalizeTrackingMode(
        data['trackingMode'] ?? data['tracking_mode'],
      ),
    if (isUpdate)
      'trackingMode':
          data.containsKey('trackingMode') || data.containsKey('tracking_mode')
          ? _normalizeTrackingMode(
              data['trackingMode'] ?? data['tracking_mode'],
            )
          : null,
    'platformId': _nullableTrimmedString(
      data['platformId'] ?? data['platform_id'],
    ),
    'accountNumber': _nullableTrimmedString(
      data['accountNumber'] ?? data['account_number'],
    ),
    'meta': _nullableTrimmedString(data['meta']),
    'provider': _nullableTrimmedString(data['provider']),
    'providerAccountId': _nullableTrimmedString(
      data['providerAccountId'] ?? data['provider_account_id'],
    ),
  };
  payload.removeWhere((key, value) => value == null);
  return payload;
}

Map<String, dynamic> normalizeActivityPayloadForRest(
  Map<String, dynamic> data, {
  bool isUpdate = false,
}) {
  final activityType = (data['activityType'] ?? data['activity_type'] ?? '')
      .toString()
      .trim()
      .toUpperCase();
  final symbolValue = data['symbol'];
  final normalizedSymbol = _normalizeSymbolInput(symbolValue);
  final quantity = _normalizeDecimalField(data['quantity']);
  final unitPrice = _normalizeDecimalField(
    data['unitPrice'] ?? data['unit_price'],
  );
  final fee = _normalizeDecimalField(data['fee']);
  final amount = _normalizeAmountField(
    data['amount'],
    activityType: activityType,
    quantity: quantity,
    unitPrice: unitPrice,
    fee: fee,
  );

  final payload = <String, dynamic>{
    if (isUpdate && (data['id'] ?? '').toString().isNotEmpty) 'id': data['id'],
    'accountId': (data['accountId'] ?? data['account_id'] ?? '')
        .toString()
        .trim(),
    'symbol': ?normalizedSymbol,
    'activityType': activityType,
    'activityDate': (data['activityDate'] ?? data['activity_date'] ?? '')
        .toString()
        .trim(),
    'quantity': quantity,
    'unitPrice': unitPrice,
    'amount': amount,
    'currency': (data['currency'] ?? '').toString().trim().toUpperCase(),
    'fee': fee,
    'status': _normalizeActivityStatus(data),
    // Server struct uses `notes` (accepts `comment` as a serde alias).
    'notes': _nullableTrimmedString(data['notes'] ?? data['comment']),
    'fxRate': _normalizeDecimalField(data['fxRate'] ?? data['fx_rate']),
    'metadata': _normalizeMetadataField(data['metadata']),
  };
  payload.removeWhere((key, value) => value == null);
  return payload;
}

String _normalizeUrl(String serverUrl) {
  return serverUrl.trim().replaceFirst(RegExp(r'/$'), '');
}

Map<String, dynamic>? _normalizeSymbolInput(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) {
    final map = parseMap(raw);
    final normalized = <String, dynamic>{
      'id': _nullableTrimmedString(
        map['id'] ?? map['assetId'] ?? map['asset_id'],
      ),
      'symbol': _nullableTrimmedString(
        map['symbol'] ?? map['assetId'] ?? map['asset_id'] ?? map['ticker'],
      )?.toUpperCase(),
      'exchangeMic': _nullableTrimmedString(
        map['exchangeMic'] ?? map['exchange_mic'],
      )?.toUpperCase(),
      'kind': _nullableTrimmedString(map['kind']),
      'name': _nullableTrimmedString(map['name']),
      'quoteMode': _nullableTrimmedString(
        map['quoteMode'] ?? map['quote_mode'],
      )?.toUpperCase(),
      'quoteCcy': _nullableTrimmedString(
        map['quoteCcy'] ?? map['quote_ccy'],
      )?.toUpperCase(),
      'instrumentType': _nullableTrimmedString(
        map['instrumentType'] ?? map['instrument_type'],
      )?.toUpperCase(),
    };
    normalized.removeWhere((key, value) => value == null);
    return normalized.isEmpty ? null : normalized;
  }

  final symbol = raw.toString().trim().toUpperCase();
  if (symbol.isEmpty) return null;
  return <String, dynamic>{'symbol': symbol};
}

String? _normalizeTrackingMode(dynamic raw) {
  final value = _nullableTrimmedString(raw)?.toUpperCase();
  if (value == null || value.isEmpty) return 'NOT_SET';
  return switch (value) {
    'TRANSACTIONS' || 'HOLDINGS' || 'NOT_SET' => value,
    'NOTSET' => 'NOT_SET',
    _ => 'NOT_SET',
  };
}

String? _normalizeActivityStatus(Map<String, dynamic> data) {
  final explicit = _nullableTrimmedString(data['status'])?.toUpperCase();
  if (explicit != null) return explicit;
  final isDraft = data['isDraft'] ?? data['is_draft'];
  return _coerceBool(isDraft) ? 'DRAFT' : null;
}

String? _normalizeMetadataField(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (raw is Map || raw is List) {
    return jsonEncode(raw);
  }
  return raw.toString();
}

String? _normalizeAmountField(
  dynamic raw, {
  required String activityType,
  required String? quantity,
  required String? unitPrice,
  required String? fee,
}) {
  final explicit = _normalizeDecimalField(raw);
  if (explicit != null) return explicit;

  final quantityValue = double.tryParse(quantity ?? '');
  final unitPriceValue = double.tryParse(unitPrice ?? '');
  if (quantityValue == null || unitPriceValue == null) {
    if (_isFeeLikeActivity(activityType)) {
      return fee;
    }
    return null;
  }

  final computed = quantityValue * unitPriceValue;
  if (_isAmountDrivenActivity(activityType) ||
      _isFeeLikeActivity(activityType)) {
    return _decimalToApiString(computed);
  }
  return null;
}

bool _isAmountDrivenActivity(String activityType) {
  return switch (activityType) {
    'DEPOSIT' ||
    'WITHDRAWAL' ||
    'DIVIDEND' ||
    'INTEREST' ||
    'TRANSFER_IN' ||
    'TRANSFER_OUT' => true,
    _ => false,
  };
}

bool _isFeeLikeActivity(String activityType) {
  return activityType == 'FEE' || activityType == 'TAX';
}

String? _normalizeDecimalField(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return _decimalToApiString(raw.toDouble());
  final trimmed = raw.toString().trim();
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  return parsed == null ? null : _decimalToApiString(parsed);
}

String _decimalToApiString(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String? _nullableTrimmedString(dynamic raw) {
  if (raw == null) return null;
  final trimmed = raw.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _coerceBool(dynamic raw, {bool fallback = false}) {
  if (raw == null) return fallback;
  if (raw is bool) return raw;
  final value = raw.toString().trim().toLowerCase();
  if (value == 'true') return true;
  if (value == 'false') return false;
  return fallback;
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
