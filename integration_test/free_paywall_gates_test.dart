import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Runs on the FREE account. launchAndSignIn() forces trialEndDate to the past
  // and subscriptionStatus='free', so a stale/lapsed account can never
  // silently grant a trial and skip these gates.
  testWidgetsWithScreenshots('Free paywall gates', (WidgetTester tester) async {
    await launchAndSignIn(tester);

    // ── 1. Home AppBar Pro-gated shortcuts all route to the paywall ─────────
    for (final icon in <IconData>[
      Icons.event_repeat, // Subscriptions (recurring payments)
      Icons.handshake_outlined, // Lent Money
      Icons.trending_up, // Forecast
      Icons.flag_outlined, // Goals
    ]) {
      await tapWhenVisible(tester, find.byIcon(icon));
      await assertUpgradeScreen(tester); // asserts paywall, closes back home
    }

    // ── 2. QR FAB is Pro-gated too ──────────────────────────────────────────
    await tapWhenVisible(tester, find.byIcon(Icons.qr_code_scanner));
    await assertUpgradeScreen(tester);

    // ── 3. Budgets: Settings → General → Set Budget shows the lock ─────────
    await tapNavTab(tester, Icons.tune_rounded, 'Settings');
    await tapUntilMarker(tester, find.text('General'), find.text('Set Budget'));
    await tapUntilMarker(tester, find.text('Set Budget'), find.text('Budgeting'));
    expect(find.text('Budgeting'), findsWidgets);
    expect(find.text('Upgrade to Pro'), findsWidgets);
    await popScreen(tester); // back to General
    await waitFor(tester, find.text('Manage Categories'));

    // NOTE: the SMS Import gate (Settings → Automation) is intentionally NOT
    // covered here — SmsImportScreen requests READ_SMS in initState, which pops
    // an un-dismissable Android system dialog on the CI emulator.

    // ── 4. Analytics exports are Pro-gated behind the ⋮ menu ────────────────
    await tapNavTab(
      tester,
      Icons.pie_chart_outline_rounded,
      'Analytics & Reports',
    );
    for (final entry in <(String, String)>[
      ('Export CSV', 'Data Export'),
      ('Tax Summary PDF', 'Tax Summary'),
      ('Share Report', 'Share Report'),
    ]) {
      await tapWhenVisible(tester, find.byIcon(Icons.more_vert));
      await tapWhenVisible(tester, find.text(entry.$1));
      await waitFor(tester, find.text(entry.$2));
      expect(find.text(entry.$2), findsWidgets);
      await dismissDialogs(tester); // closes the ProLock bottom sheet
      await pumpReal(tester);
    }

    // ── 5. Back home ────────────────────────────────────────────────────────
    await tapNavTab(tester, Icons.grid_view_rounded, 'Total Balance');
    expect(find.text('Total Balance'), findsWidgets);
  });
}
