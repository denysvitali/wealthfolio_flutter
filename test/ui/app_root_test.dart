import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wealthfolio_flutter/core/api/wealthfolio_api.dart';
import 'package:wealthfolio_flutter/core/models/account.dart';
import 'package:wealthfolio_flutter/core/models/holding.dart';
import 'package:wealthfolio_flutter/core/models/session.dart';
import 'package:wealthfolio_flutter/core/services/app_controller.dart';
import 'package:wealthfolio_flutter/core/services/session_storage.dart';
import 'package:wealthfolio_flutter/core/services/theme_controller.dart';
import 'package:wealthfolio_flutter/features/auth/connect_screen.dart';
import 'package:wealthfolio_flutter/ui/app_root.dart';

import '../test_helpers/fake_wealthfolio_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('app shows connect form when no session exists', (tester) async {
    final controller = AppController(
      storage: MemorySessionStorage(),
      api: FakeWealthfolioApi(),
    );
    final themeController = ThemeController();

    await tester.pumpWidget(
      WealthfolioApp(
        controller: controller,
        themeController: themeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect to your Wealthfolio server'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('connect form submits credentials and switches to authenticated shell', (
    tester,
  ) async {
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
    final themeController = ThemeController();

    await tester.pumpWidget(
      WealthfolioApp(
        controller: controller,
        themeController: themeController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'http://localhost:8088',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'alice');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(api.lastSignInServerUrl, 'http://localhost:8088');
    expect(api.lastUsername, 'alice');
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Holdings'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Accounts'), findsOneWidget);
  });

  testWidgets(
    'connect form pre-fills server URL and username from saved credentials',
    (tester) async {
      final storage = MemorySessionStorage();
      await storage.saveCredentials(
        serverUrl: 'https://saved.example.com',
        username: 'alice',
        password: 'secret',
      );
      // Reject auto-login so the connect screen is shown and we can verify
      // the pre-fill instead of going straight to the authenticated shell.
      final api = FakeWealthfolioApi()
        ..signInError = const WealthfolioException('401 unauthorized');
      final controller = AppController(storage: storage, api: api);

      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(home: ConnectScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      final serverField =
          tester.widget<TextFormField>(find.byType(TextFormField).at(0));
      final usernameField =
          tester.widget<TextFormField>(find.byType(TextFormField).at(1));

      expect(serverField.controller?.text, 'https://saved.example.com');
      expect(usernameField.controller?.text, 'alice');
    },
  );
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
