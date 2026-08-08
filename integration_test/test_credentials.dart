// Integration-test account credentials.
//
// Pass them at runtime, never hard-code them:
//   flutter test integration_test --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
// CI injects them from GitHub secrets. Leave empty locally to force a clear
// failure instead of silently logging into a real account from the repo.
const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kTestPassword = String.fromEnvironment(
  'TEST_PASSWORD',
  defaultValue: '',
);
