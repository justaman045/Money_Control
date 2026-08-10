// Integration-test account credentials.
//
// Pass them at runtime, never hard-code them:
//   flutter test integration_test --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
// CI injects them from GitHub secrets. Leave empty locally to force a clear
// failure instead of silently logging into a real account from the repo.
//
// Two accounts, never shared:
//  - TEST_EMAIL/TEST_PASSWORD  = the FREE account (paywall gates + free
//    features). The harness force-resets it to Free on every launch, so it is
//    deterministic.
//  - PRO_TEST_EMAIL/PRO_TEST_PASSWORD = the PRO account (Pro feature flows).
//    It must be configured out-of-band in the Firebase console with
//    subscriptionStatus:"pro" + a far-future expiryDate; the app cannot
//    self-grant Pro. If it lapses, `ensureAccountState` fails loudly.
const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kTestPassword = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: '',
);
const String kProTestEmail = String.fromEnvironment(
  'PRO_TEST_EMAIL',
  defaultValue: '',
);
const String kProTestPassword = String.fromEnvironment(
  'PRO_TEST_PASSWORD',
  defaultValue: '',
);
