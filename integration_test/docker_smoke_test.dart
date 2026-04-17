import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wealthfolio_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connects to Docker-backed Wealthfolio and loads the empty dashboard', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Connect to your Wealthfolio server'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'http://127.0.0.1:8088');
    await tester.enterText(find.byType(EditableText).at(1), 'ci');
    await tester.enterText(find.byType(EditableText).at(2), '');
    await tester.tap(find.text('Connect'));

    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('No holdings yet'), findsOneWidget);
  });
}
