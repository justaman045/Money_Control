// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('End-to-End App Flow: Login -> Home -> Navigation', (
    WidgetTester tester,
  ) async {
    // 1-3. App Launch + Splash/Onboarding + Login
    await launchAndSignIn(tester);

    // 4. Verify Home Screen
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.textContaining('Welcome'), findsWidgets);

    // 5. Navigation Test: Analytics tab (Index 1).
    // Nav labels only render on the ACTIVE item, so tap by icon.
    await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
    await pumpAndSettleSafe(tester);
    expect(find.text('Analytics & Reports'), findsOneWidget); // screen title

    // 6. Wealth tab (Index 3)
    await tester.tap(find.byIcon(Icons.monetization_on_outlined));
    await pumpAndSettleSafe(tester);
    expect(find.text('Wealth Builder'), findsOneWidget); // screen title

    // 7. Return to Home
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await pumpAndSettleSafe(tester);
    expect(find.text('Total Balance'), findsOneWidget);

    print("E2E Test Completed Successfully!");
  });
}
