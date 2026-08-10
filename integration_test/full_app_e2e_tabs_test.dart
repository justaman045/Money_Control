import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgetsWithScreenshots(
    'E2E: login -> home -> tab tour (analytics, wealth, settings)',
    (WidgetTester tester) async {
      await launchAndSignIn(tester);

      // ── 1. Home ─────────────────────────────────────────────────────────────
      expect(find.text('Total Balance'), findsWidgets);
      expect(find.text('Recent Transactions'), findsWidgets);
      expect(find.textContaining('Welcome'), findsWidgets);

      // ── 2. Analytics tab ────────────────────────────────────────────────────
      await tapNavTab(
        tester,
        Icons.pie_chart_outline_rounded,
        'Financial Summary',
      );
      expect(find.text('Net Balance'), findsWidgets);

      // ── 3. Wealth tab ───────────────────────────────────────────────────────
      await tapNavTab(tester, Icons.monetization_on_outlined, 'Wealth Builder');
      expect(find.text('Wealth Builder'), findsWidgets);

      // ── 4. Settings tab ─────────────────────────────────────────────────────
      await tapNavTab(tester, Icons.tune_rounded, 'Settings');
      expect(find.text('General'), findsWidgets);
      expect(find.text('Sign Out'), findsWidgets);

      // ── 5. Back to the home tab ─────────────────────────────────────────────
      await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
      expect(find.text('Total Balance'), findsWidgets);
    },
  );
}
