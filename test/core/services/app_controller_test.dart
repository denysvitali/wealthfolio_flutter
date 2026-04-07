import 'package:flutter_test/flutter_test.dart';
import 'package:wealthfolio_flutter/core/api/wealthfolio_api.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';
import 'package:wealthfolio_flutter/core/models/settings.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/services/session_storage.dart';

import '../../test_helpers/fake_wealthfolio_api.dart';

void main() {
  group('AppController', () {
    test(
      'initialize without stored session enters unauthenticated stage',
      () async {
        final controller = AppController(
          storage: MemorySessionStorage(),
          api: FakeWealthfolioApi(),
        );

        await controller.initialize();

        expect(controller.stage, AppStage.unauthenticated);
        expect(controller.session, isNull);
        expect(controller.accounts, isEmpty);
        expect(controller.holdings, isEmpty);
      },
    );

    test(
      'initialize restores session and loads accounts, holdings, and settings',
      () async {
        final storage = MemorySessionStorage();
        await storage.saveSession(
          const AppSession(
            serverUrl: 'http://localhost:8088',
            token: 'restored-token',
            username: 'admin',
          ),
        );

        final api = FakeWealthfolioApi(
          accounts: <Account>[_account()],
          holdingsByAccountId: <String, List<Holding>>{
            'acc-1': <Holding>[_holding(accountId: 'acc-1')],
          },
          settings: const Settings(
            id: 'settings',
            theme: 'system',
            font: 'inter',
            baseCurrency: 'CHF',
          ),
        );
        final controller = AppController(storage: storage, api: api);

        await controller.initialize();

        expect(controller.stage, AppStage.authenticated);
        expect(controller.session?.token, 'restored-token');
        expect(controller.accounts, hasLength(1));
        expect(controller.holdings, hasLength(1));
        expect(controller.baseCurrency, 'CHF');
        expect(controller.errorMessage, isNull);
      },
    );

    test('initialize clears expired session on auth failure', () async {
      final storage = MemorySessionStorage();
      await storage.saveSession(
        const AppSession(
          serverUrl: 'http://localhost:8088',
          token: 'expired-token',
          username: 'admin',
        ),
      );

      final api = FakeWealthfolioApi()
        ..authStatusError = const WealthfolioException('401 unauthorized');
      final controller = AppController(storage: storage, api: api);

      await controller.initialize();

      expect(controller.stage, AppStage.unauthenticated);
      expect(controller.session, isNull);
      expect(controller.errorMessage, 'Saved session expired. Sign in again.');
      expect(await storage.loadSession(), isNull);
    });

    test(
      'initialize re-authenticates expired session with stored credentials',
      () async {
        final storage = MemorySessionStorage();
        await storage.saveCredentials(
          serverUrl: 'http://localhost:8088',
          username: 'alice',
          password: 'secret',
        );
        await storage.saveSession(
          const AppSession(
            serverUrl: 'http://localhost:8088',
            token: 'expired-token',
            username: 'alice',
          ),
        );

        final api = FakeWealthfolioApi(
          signInSession: const AppSession(
            serverUrl: 'http://localhost:8088',
            token: 'fresh-token',
            username: 'alice',
          ),
          accounts: <Account>[_account()],
          holdingsByAccountId: <String, List<Holding>>{
            'acc-1': <Holding>[_holding(accountId: 'acc-1')],
          },
        )..authStatusError = const WealthfolioException('401 unauthorized');
        final controller = AppController(storage: storage, api: api);

        await controller.initialize();

        expect(controller.stage, AppStage.authenticated);
        expect(controller.session?.token, 'fresh-token');
        expect(api.lastSignInServerUrl, 'http://localhost:8088');
        expect(api.lastUsername, 'alice');
        expect(api.lastPassword, 'secret');
        expect(await storage.loadSession(), isNotNull);
        expect(controller.accounts, hasLength(1));
        expect(controller.holdings, hasLength(1));
        expect(controller.errorMessage, isNull);
      },
    );

    test('signIn persists session and loads portfolio data', () async {
      final storage = MemorySessionStorage();
      final api = FakeWealthfolioApi(
        signInSession: const AppSession(
          serverUrl: 'http://localhost:8088',
          token: 'fresh-token',
          username: 'alice',
        ),
        accounts: <Account>[_account()],
        holdingsByAccountId: <String, List<Holding>>{
          'acc-1': <Holding>[_holding(accountId: 'acc-1')],
        },
      );
      final controller = AppController(storage: storage, api: api);

      await controller.signIn(
        serverUrl: 'http://localhost:8088 ',
        username: 'alice ',
        password: 'secret',
      );

      expect(controller.stage, AppStage.authenticated);
      expect(controller.session?.token, 'fresh-token');
      expect(api.lastSignInServerUrl, 'http://localhost:8088');
      expect(api.lastUsername, 'alice');
      expect(api.lastPassword, 'secret');
      expect(await storage.loadSession(), isNotNull);
      final credentials = await storage.loadCredentials();
      expect(credentials, isNotNull);
      expect(credentials?.serverUrl, 'http://localhost:8088');
      expect(credentials?.username, 'alice');
      expect(credentials?.password, 'secret');
      expect(controller.accounts, hasLength(1));
      expect(controller.holdings, hasLength(1));
      expect(controller.errorMessage, isNull);
    });

    test('signOut clears stored credentials', () async {
      final storage = MemorySessionStorage();
      await storage.saveCredentials(
        serverUrl: 'http://localhost:8088',
        username: 'alice',
        password: 'secret',
      );
      await storage.saveSession(
        const AppSession(
          serverUrl: 'http://localhost:8088',
          token: 'token',
          username: 'alice',
        ),
      );

      final controller = AppController(
        storage: storage,
        api: FakeWealthfolioApi(),
      );

      await controller.signOut();

      expect(await storage.loadSession(), isNull);
      expect(await storage.loadCredentials(), isNull);
      expect(controller.stage, AppStage.unauthenticated);
    });

    test(
      'createActivity sends symbol as object with quoteCcy for asset-backed types',
      () async {
        final api = FakeWealthfolioApi(
          signInSession: const AppSession(
            serverUrl: 'http://localhost:8088',
            token: 'token',
            username: 'alice',
          ),
          accounts: <Account>[_account()],
          holdingsByAccountId: <String, List<Holding>>{
            'acc-1': <Holding>[],
          },
        );
        final controller = AppController(
          storage: MemorySessionStorage(),
          api: api,
        );

        await controller.signIn(
          serverUrl: 'http://localhost:8088',
          username: 'alice',
          password: 'secret',
        );

        await controller.createActivity(<String, dynamic>{
          'accountId': 'acc-1',
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
        });

        // This test would have caught the original bug:
        // The old code sent 'symbol': 'AAPL' (plain string) which the backend
        // rejected with "Quote currency is required".
        final payload = api.lastActivityPayload;
        expect(payload, isNotNull);
        expect(payload!['symbol'], isA<Map<String, dynamic>>());
        expect(payload['symbol']['symbol'], 'AAPL');
        expect(payload['symbol']['quoteCcy'], 'USD');
      },
    );

    test(
      'createActivity with plain string symbol is rejected by contract test',
      () async {
        final api = FakeWealthfolioApi(
          signInSession: const AppSession(
            serverUrl: 'http://localhost:8088',
            token: 'token',
            username: 'alice',
          ),
          accounts: <Account>[_account()],
          holdingsByAccountId: <String, List<Holding>>{
            'acc-1': <Holding>[],
          },
        );
        // Simulate the backend rejecting a plain string symbol (no quoteCcy)
        api.createActivityError = const WealthfolioException(
          'Invalid data: Quote currency is required. Please re-select the symbol.',
        );
        final controller = AppController(
          storage: MemorySessionStorage(),
          api: api,
        );

        await controller.signIn(
          serverUrl: 'http://localhost:8088',
          username: 'alice',
          password: 'secret',
        );

        // This documents the failure mode: sending a plain string symbol
        // (without quoteCcy) will be rejected by the backend.
        expect(
          controller.createActivity(<String, dynamic>{
            'accountId': 'acc-1',
            'activityType': 'BUY',
            'activityDate': '2026-04-07',
            'quantity': 10.0,
            'unitPrice': 150.0,
            'currency': 'USD',
            'fee': 0.0,
            'isDraft': false,
            'symbol': 'AAPL', // plain string — no quoteCcy
          }),
          throwsA(isA<WealthfolioException>()),
        );
      },
    );

    test(
      'connectToServer surfaces API errors through controller error state',
      () async {
        final api = FakeWealthfolioApi()
          ..verifyServerError = const WealthfolioException(
            'Server unavailable',
          );
        final controller = AppController(
          storage: MemorySessionStorage(),
          api: api,
        );

        await expectLater(
          controller.connectToServer('http://localhost:8088'),
          throwsA(isA<WealthfolioException>()),
        );

        expect(controller.errorMessage, 'Server unavailable');
        expect(controller.busy, isFalse);
      },
    );
  });
}

Account _account() {
  return const Account(
    id: 'acc-1',
    name: 'Brokerage',
    accountType: 'BROKERAGE',
    currency: 'USD',
    isDefault: true,
    isActive: true,
    isArchived: false,
    trackingMode: 'Transactions',
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
  );
}

Holding _holding({required String accountId}) {
  return Holding(
    id: 'holding-1',
    accountId: accountId,
    assetId: 'asset-1',
    symbol: 'VTI',
    name: 'Vanguard Total Stock Market ETF',
    holdingType: 'ETF',
    quantity: 5,
    marketValue: 1000,
    bookValue: 800,
    averageCost: 160,
    currency: 'USD',
    baseCurrency: 'USD',
    marketValueConverted: 1000,
    bookValueConverted: 800,
    unrealizedGain: 200,
    unrealizedGainPercent: 25,
    dayChange: 5,
    dayChangePercent: 0.5,
  );
}
