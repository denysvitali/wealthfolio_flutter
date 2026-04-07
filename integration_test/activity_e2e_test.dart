import 'dart:io';

import 'package:dio/dio.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2E integration test for activity creation against a running Wealthfolio server.
/// Uses the real REST API via Dio.
///
/// Required env vars:
///   WEALTHFOLIO_URL - e.g. http://localhost:8088
///   WEALTHFOLIO_PASSWORD - password for authentication
///
/// Run with: dart run integration_test/activity_e2e_test.dart
///    or: flutter test integration_test/activity_e2e_test.dart
///
/// This test validates the activity contract: symbol must be an object with
/// quoteCcy, not a plain string. It catches contract mismatches at test time
/// rather than at runtime in the app.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final url = Platform.environment['WEALTHFOLIO_URL'] ?? 'http://localhost:8088';
  final password = Platform.environment['WEALTHFOLIO_PASSWORD'] ?? 'testpassword';

  group('Activity E2E', () {
    late Dio dio;
    String? token;
    String? testAccountId;

    setUpAll(() async {
      dio = Dio(BaseOptions(
        baseUrl: '$url/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
    });

    tearDownAll(() async {
      // Clean up test account if created
      if (testAccountId != null && token != null) {
        try {
          await dio.delete(
            '/accounts/${Uri.encodeComponent(testAccountId!)}',
            options: Options(headers: {'Cookie': 'wf_session=$token'}),
          );
        } catch (_) {}
      }
      dio.close();
    });

    Future<void> _authenticate() async {
      final loginResponse = await dio.post('/auth/login', data: {'password': password});
      _checkStatus(loginResponse, 'login');

      final cookies = loginResponse.headers['set-cookie'];
      if (cookies != null) {
        for (final cookie in cookies) {
          if (cookie.startsWith('wf_session=')) {
            token = cookie.split(';')[0].replaceFirst('wf_session=', '');
            break;
          }
        }
      }
      token ??= loginResponse.data['token']?.toString();
      if (token == null) {
        throw Exception('No token received from login');
      }
    }

    Future<String> _createTestAccount() async {
      final createResponse = await dio.post(
        '/accounts',
        data: {
          'name': 'E2E Test Account',
          'accountType': 'BROKERAGE',
          'currency': 'USD',
          'isDefault': false,
          'isActive': true,
          'trackingMode': 'Holdings',
        },
        options: Options(headers: {'Cookie': 'wf_session=$token'}),
      );
      _checkStatus(createResponse, 'create account');
      final accountId = createResponse.data['id']?.toString();
      if (accountId == null || accountId.isEmpty) {
        throw Exception('No account id returned from create account');
      }
      return accountId;
    }

    test('creates a BUY activity with symbol object containing quoteCcy', () async {
      await _authenticate();
      testAccountId = await _createTestAccount();

      // The contract: symbol must be an object { symbol: "...", quoteCcy: "..." }
      // Sending just a string will fail with "Quote currency is required"
      final activityData = <String, dynamic>{
        'accountId': testAccountId,
        'activityType': 'BUY',
        'activityDate': '2026-04-07',
        'quantity': 10.0,
        'unitPrice': 150.0,
        'currency': 'USD',
        'fee': 0.0,
        'isDraft': false,
        'symbol': <String, dynamic>{
          'symbol': 'AAPL',
          'quoteCcy': 'USD',
        },
      };

      final createResponse = await dio.post(
        '/activities',
        data: activityData,
        options: Options(headers: {'Cookie': 'wf_session=$token'}),
      );

      _checkStatus(createResponse, 'create BUY activity');
      expect(createResponse.data, isA<Map<String, dynamic>>());
      expect(createResponse.data['id'], isNotEmpty);
      expect(createResponse.data['symbol'], isA<Map<String, dynamic>>());
      expect(createResponse.data['symbol']['symbol'], 'AAPL');
      expect(createResponse.data['symbol']['quoteCcy'], 'USD');
      expect(createResponse.data['quantity'], 10.0);
      expect(createResponse.data['unitPrice'], 150.0);
    });

    test('creates a DIVIDEND activity with symbol object containing quoteCcy', () async {
      await _authenticate();
      testAccountId = await _createTestAccount();

      final activityData = <String, dynamic>{
        'accountId': testAccountId,
        'activityType': 'DIVIDEND',
        'activityDate': '2026-04-07',
        'quantity': 10.0,
        'unitPrice': 1.50, // dividend per share
        'currency': 'USD',
        'fee': 0.0,
        'isDraft': false,
        'symbol': <String, dynamic>{
          'symbol': 'AAPL',
          'quoteCcy': 'USD',
        },
      };

      final createResponse = await dio.post(
        '/activities',
        data: activityData,
        options: Options(headers: {'Cookie': 'wf_session=$token'}),
      );

      _checkStatus(createResponse, 'create DIVIDEND activity');
      expect(createResponse.data['activityType'], 'DIVIDEND');
      expect(createResponse.data['symbol']['symbol'], 'AAPL');
    });

    test('creates a DEPOSIT activity (no symbol required)', () async {
      await _authenticate();
      testAccountId = await _createTestAccount();

      final activityData = <String, dynamic>{
        'accountId': testAccountId,
        'activityType': 'DEPOSIT',
        'activityDate': '2026-04-07',
        'quantity': 0,
        'unitPrice': 0,
        'amount': 5000.0,
        'currency': 'USD',
        'fee': 0.0,
        'isDraft': false,
      };

      final createResponse = await dio.post(
        '/activities',
        data: activityData,
        options: Options(headers: {'Cookie': 'wf_session=$token'}),
      );

      _checkStatus(createResponse, 'create DEPOSIT activity');
      expect(createResponse.data['activityType'], 'DEPOSIT');
      expect(createResponse.data['amount'], 5000.0);
    });

    test('rejects a BUY activity when quoteCcy is missing', () async {
      await _authenticate();
      testAccountId = await _createTestAccount();

      // Intentionally malformed: symbol as plain string instead of object
      final activityData = <String, dynamic>{
        'accountId': testAccountId,
        'activityType': 'BUY',
        'activityDate': '2026-04-07',
        'quantity': 10.0,
        'unitPrice': 150.0,
        'currency': 'USD',
        'fee': 0.0,
        'isDraft': false,
        'symbol': 'AAPL', // Wrong: should be { symbol: 'AAPL', quoteCcy: 'USD' }
      };

      try {
        await dio.post(
          '/activities',
          data: activityData,
          options: Options(headers: {'Cookie': 'wf_session=$token'}),
        );
        fail('Expected request to fail with missing quoteCcy error');
      } on DioException catch (e) {
        expect(e.response?.statusCode, anyOf([400, 422]));
        final data = e.response?.data?.toString() ?? '';
        expect(data.toLowerCase(), anyOf(contains('quote'), contains('currency'), contains('required')));
      }
    });

    test('searches symbols via market-data/search endpoint', () async {
      await _authenticate();

      final response = await dio.get(
        '/market-data/search',
        queryParameters: {'query': 'AAPL'},
        options: Options(headers: {'Cookie': 'wf_session=$token'}),
      );

      _checkStatus(response, 'search symbols');
      expect(response.data, isA<List>());
      final results = response.data as List;
      expect(results, isNotEmpty);
      // Each result should have symbol and quote currency info
      final first = results.first as Map<String, dynamic>;
      expect(first['symbol'] ?? first['ticker'], isNotEmpty);
    });
  });
}

void _checkStatus(Response<dynamic> response, String operation) {
  final status = response.statusCode ?? 0;
  if (status < 200 || status >= 300) {
    throw Exception(
      '$operation failed with status $status: ${response.data}',
    );
  }
}
