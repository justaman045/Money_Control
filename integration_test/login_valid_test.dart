// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'test_helpers.dart';

// Runs in its own process (own mainCommon) so the top-level `themeController`
// is only assigned once. Kept separate from login_test.dart to avoid the
// "LateInitializationError: Field 'themeController' has already been
// initialized." crash that occurs when mainCommon runs twice in one process.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Login Test: Valid Credentials Flow', (WidgetTester tester) async {
    await launchAndSignIn(tester);

    expect(find.byType(BankingHomeScreen), findsOneWidget);
    print('Valid Login Test Passed: Navigated to Home.');
  });
}
