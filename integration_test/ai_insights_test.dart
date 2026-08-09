import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('AI Insights full flow', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);

    // Seed one expense so the insights engine has data to aggregate (it shows a
    // no-data message otherwise). A single expense is enough for the forecast
    // and category insights — the income seeding step was dropped because it
    // pushed the file's runtime onto the emulator's ~7m software-GL crash line.
    await createTransaction(
      tester,
      receive: false,
      name: uniqueName('Ana'),
      amount: '500',
    );

    // ── 1. AI Insights tab ──────────────────────────────────────────────────
    await tapNavTab(tester, Icons.auto_awesome_outlined, 'AI Insights');
    await waitFor(tester, find.text('This Month Forecast'));
    expect(find.text('This Month Forecast'), findsWidgets);

    await scrollUntilVisible(tester, find.textContaining('Category Insights'));
    expect(find.textContaining('Category Insights'), findsWidgets);

    // ── 2. Back to the home tab ─────────────────────────────────────────────
    await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
