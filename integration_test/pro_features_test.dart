import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Runs on the PRO account (PRO_TEST_EMAIL, configured with
  // subscriptionStatus:'pro' in the Firebase console). Verifies that the
  // home AppBar Pro shortcuts open their real screens — NOT the paywall —
  // i.e. the subscription state genuinely unlocks the features. No data is
  // mutated here (the adaptive tests on this account exercise the add/edit/
  // delete flows).
  testWidgetsWithScreenshots('Pro unlocks real screens (recurring, lent, goals, forecast)', (
    WidgetTester tester,
  ) async {
    await launchAndSignIn(tester, account: TestAccount.pro);

    await tapWhenVisible(tester, find.byIcon(Icons.event_repeat));
    await waitFor(tester, find.text('Subscriptions'));
    expect(find.text('Subscriptions'), findsWidgets);
    await popScreen(tester);
    await waitForHome(tester);

    await tapWhenVisible(tester, find.byIcon(Icons.handshake_outlined));
    await waitFor(tester, find.text('Lent Money Tracker'));
    expect(find.text('Lent Money Tracker'), findsWidgets);
    await popScreen(tester);
    await waitForHome(tester);

    await tapWhenVisible(tester, find.byIcon(Icons.flag_outlined));
    await waitFor(tester, find.text('Goals'));
    expect(find.text('Goals'), findsWidgets);
    await popScreen(tester);
    await waitForHome(tester);

    await tapWhenVisible(tester, find.byIcon(Icons.trending_up));
    await waitFor(tester, find.text('Monthly Forecast'));
    expect(find.text('Monthly Forecast'), findsWidgets);
    await popScreen(tester);
    await waitForHome(tester);
  });
}
