// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots(
    'End-to-End App Flow: Login -> Home -> Navigation',
    (WidgetTester tester) async {
      // 1-3. App Launch + Splash/Onboarding + Login
      await launchAndSignIn(tester);

      // 4. Verify Home Screen
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.textContaining('Welcome'), findsWidgets);

      // 5. Navigation Test: Analytics tab (Index 1).
      // Nav labels only render on the ACTIVE item, so tap by icon. The auto-
      // hiding bottom bar can be translated off-screen (raw taps at its icon's
      // stale rect then miss — y=597 vs a 569-logical-tall screen), so use the
      // reveal+retry helper instead of a bare tap.
      await tapNavTab(
        tester,
        Icons.pie_chart_outline_rounded,
        'Analytics & Reports',
      );
      expect(find.text('Analytics & Reports'), findsOneWidget); // screen title

      // 6. Wealth tab (Index 3)
      await tapNavTab(tester, Icons.monetization_on_outlined, 'Wealth Builder');
      expect(find.text('Wealth Builder'), findsOneWidget); // screen title

      // 7. Return to Home
      await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
      expect(find.text('Total Balance'), findsOneWidget);

      print("E2E Test Completed Successfully!");
    },
  );
}
