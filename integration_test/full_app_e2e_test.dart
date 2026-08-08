import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Full app tour: home, transaction, all tabs', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester);

    // ── 1. Home ─────────────────────────────────────────────────────────────
    expect(find.text('Total Balance'), findsWidgets);

    // ── 2. Create a small expense through the UI ────────────────────────────
    final name = uniqueName('Tour');
    await createTransaction(
      tester,
      receive: false,
      name: name,
      amount: '123',
    );
    expect(find.text('Total Balance'), findsWidgets);

    // ── 3. Analytics tab ────────────────────────────────────────────────────
    await tapNavTab(tester, Icons.pie_chart_outline_rounded, 'Financial Summary');
    expect(find.text('Net Balance'), findsWidgets);

    // ── 4. AI Insights tab ──────────────────────────────────────────────────
    await tapNavTab(tester, Icons.auto_awesome_outlined, 'AI Insights');
    await waitFor(tester, find.text('This Month Forecast'));
    expect(find.text('This Month Forecast'), findsWidgets);

    // ── 5. Wealth tab ───────────────────────────────────────────────────────
    await tapNavTab(tester, Icons.monetization_on_outlined, 'Wealth Builder');
    expect(find.text('Wealth Builder'), findsWidgets);

    // ── 6. Settings tab ─────────────────────────────────────────────────────
    await tapNavTab(tester, Icons.tune_rounded, 'Settings');
    expect(find.text('General'), findsWidgets);
    expect(find.text('Sign Out'), findsWidgets);

    // ── 7. Back to the home tab ─────────────────────────────────────────────
    await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
