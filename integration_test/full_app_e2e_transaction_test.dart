import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('E2E: home + create a transaction', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);

    // ── 1. Home ─────────────────────────────────────────────────────────────
    expect(find.text('Total Balance'), findsWidgets);

    // ── 2. Create a small expense through the UI ────────────────────────────
    final name = uniqueName('Tour');
    await createTransaction(tester, receive: false, name: name, amount: '123');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
