import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Subscription screen (adaptive Pro/trial/free)', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);
    final isPro = await probePro(tester);

    await tapNavTab(tester, Icons.tune_rounded, 'Settings');

    if (isPro) {
      // Shared test account is inside its trial window → trial banner.
      await tapUntilMarker(tester, find.text('Managing Subscription'), find.text('Free Trial Active'));
      expect(find.text('Free Trial Active'), findsWidgets);
      expect(find.text('Unlimited Transactions'), findsWidgets);
      expect(find.text('Smart Budgeting'), findsWidgets);
      expect(find.text('Upgrade to Pro Now'), findsWidgets);

      // NEVER tap "End Trial" — it would end the shared account's trial and
      // break every other Pro-gated test. Close and continue.
      await tapUntilMarker(tester, find.byIcon(Icons.close), find.text('General'));
    } else {
      await tapUntilMarker(tester, find.text('Upgrade to Pro'), find.text('Monthly'));
      expect(find.text('Yearly'), findsWidgets);
      await tapUntilMarker(tester, find.byIcon(Icons.close), find.text('General'));
    }

    await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
