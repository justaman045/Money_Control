import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots('Analytics and AI Insights full flow', (WidgetTester tester) async {
    await launchAndSignIn(tester);

    // Seed one expense + one income so the trend chart and pie chart render
    // (both are data-dependent and hidden when the period has no transactions).
    await createTransaction(
      tester,
      receive: false,
      name: uniqueName('Ana'),
      amount: '500',
    );
    await createTransaction(
      tester,
      receive: true,
      name: uniqueName('Ana'),
      amount: '1200',
    );

    // ── 1. Analytics & Reports tab ──────────────────────────────────────────
    await tapNavTab(tester, Icons.pie_chart_outline_rounded, 'Financial Summary');
    expect(find.text('Analytics & Reports'), findsWidgets);

    // Financial summary card (Income / Expenses / Net Balance).
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Net Balance'), findsWidgets);

    // 'This Month' is the default period selector.
    expect(find.text('This Month'), findsWidgets);

    // Scroll through the deeper report sections. The trend card is titled
    // 'Monthly Trend' once two months of data exist, 'Current Period' when only
    // the current month has transactions — accept either.
    final trendTitle = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data == 'Monthly Trend' || w.data == 'Current Period'),
    );
    await waitFor(tester, trendTitle);
    expect(trendTitle, findsWidgets);
    await scrollUntilVisible(tester, trendTitle);

    await waitFor(tester, find.text('Expense Breakdown'));
    expect(find.text('Expense Breakdown'), findsWidgets);
    await scrollUntilVisible(tester, find.text('Expense Breakdown'));

    // ── 2. AI Insights tab ──────────────────────────────────────────────────
    await tapNavTab(tester, Icons.auto_awesome_outlined, 'AI Insights');
    await waitFor(tester, find.text('This Month Forecast'));
    expect(find.text('This Month Forecast'), findsWidgets);

    await scrollUntilVisible(tester, find.textContaining('Category Insights'));
    expect(find.textContaining('Category Insights'), findsWidgets);

    // ── 3. Back to the home tab ─────────────────────────────────────────────
    await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
