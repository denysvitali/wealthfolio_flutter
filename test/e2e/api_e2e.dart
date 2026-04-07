import 'dart:io';
import 'package:dio/dio.dart';

/// E2E API test against a running Wealthfolio Docker instance.
/// Run with: dart run test/e2e/api_e2e_test.dart
/// Required env vars:
///   WEALTHFOLIO_URL - e.g. http://localhost:8088
///   WEALTHFOLIO_PASSWORD - password for authentication

void main() async {
  final url = Platform.environment['WEALTHFOLIO_URL'] ?? 'http://localhost:8088';
  final password = Platform.environment['WEALTHFOLIO_PASSWORD'] ?? 'testpassword';

  print('Testing Wealthfolio API at $url');

  final dio = Dio(BaseOptions(
    baseUrl: '$url/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String? token;

  try {
    // 1. Sign in
    print('\n[1/8] Signing in...');
    final loginResponse = await dio.post('/auth/login', data: {'password': password});
    _checkStatus(loginResponse, 'login');

    // Extract token from Set-Cookie header
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
    print('  Token obtained: ${token.substring(0, 20)}...');

    // 2. Get auth status
    print('\n[2/8] Checking auth status...');
    final authResponse = await dio.get(
      '/auth/status',
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(authResponse, 'auth status');
    print('  Auth status OK');

    // 3. Fetch accounts (should be empty initially)
    print('\n[3/8] Fetching accounts...');
    final accountsResponse = await dio.get(
      '/accounts',
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(accountsResponse, 'fetch accounts');
    final accounts = accountsResponse.data as List;
    print('  Found ${accounts.length} accounts');

    // 4. Create an account
    print('\n[4/8] Creating account...');
    final createAccountResponse = await dio.post(
      '/accounts',
      data: {
        'name': 'Test Brokerage',
        'accountType': 'BROKERAGE',
        'currency': 'USD',
        'isDefault': true,
        'isActive': true,
        'trackingMode': 'Holdings',
      },
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(createAccountResponse, 'create account');
    final createdAccount = createAccountResponse.data as Map<String, dynamic>;
    final accountId = createdAccount['id']?.toString();
    if (accountId == null || accountId.isEmpty) {
      throw Exception('No account id returned from create account');
    }
    print('  Created account: $accountId');

    // 5. Fetch holdings (should be empty for new account)
    print('\n[5/8] Fetching holdings for account $accountId...');
    final holdingsResponse = await dio.get(
      '/holdings',
      queryParameters: {'accountId': accountId},
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(holdingsResponse, 'fetch holdings');
    final holdings = holdingsResponse.data as List;
    print('  Found ${holdings.length} holdings');

    // 6. Fetch settings
    print('\n[6/8] Fetching settings...');
    final settingsResponse = await dio.get(
      '/settings',
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(settingsResponse, 'fetch settings');
    print('  Settings OK: baseCurrency=${settingsResponse.data['baseCurrency']}');

    // 7. Search activities (should be empty)
    print('\n[7/8] Searching activities...');
    final activitiesResponse = await dio.post(
      '/activities/search',
      data: {
        'page': 1,
        'pageSize': 10,
      },
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(activitiesResponse, 'search activities');
    print('  Activities search OK');

    // 8. Delete the test account
    print('\n[8/8] Deleting test account...');
    final deleteResponse = await dio.delete(
      '/accounts/${Uri.encodeComponent(accountId)}',
      options: Options(headers: {'Cookie': 'wf_session=$token'}),
    );
    _checkStatus(deleteResponse, 'delete account');
    print('  Account deleted');

    print('\n✅ All E2E API tests passed!');
  } on DioException catch (e) {
    print('\n❌ API test failed:');
    print('  ${e.message}');
    if (e.response != null) {
      print('  Status: ${e.response?.statusCode}');
      print('  Data: ${e.response?.data}');
    }
    exit(1);
  } catch (e) {
    print('\n❌ Test failed: $e');
    exit(1);
  } finally {
    dio.close();
  }
}

void _checkStatus(Response<dynamic> response, String operation) {
  final status = response.statusCode ?? 0;
  if (status < 200 || status >= 300) {
    throw Exception('$operation failed with status $status: ${response.data}');
  }
}
