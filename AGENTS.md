# AGENTS.md

Critical rules and conventions for this Flutter + GetX + Firebase project.

## CRITICAL PATTERNS

### GetX Controller Access — Never Field Initializers

```dart
// WRONG — crashes (controllers not yet registered)
final _controller = Get.find<TransactionController>();

// CORRECT — guard + defer
late final TransactionController _controller;
@override
void initState() {
  super.initState();
  if (!Get.isRegistered<TransactionController>()) Get.put(TransactionController());
  _controller = Get.find<TransactionController>();
}
```

Applies to every widget using `Get.find<>()`.

### Dispose TextEditingControllers in Dialogs/Sheets

```dart
// showDialog — try/finally
final ctrl = TextEditingController();
try { await showDialog(...); } finally { ctrl.dispose(); }

// showModalBottomSheet — .whenComplete()
showModalBottomSheet(...).whenComplete(() => ctrl.dispose());
```

Multiple controllers in a sheet → `StatefulWidget` owning controllers in `initState`/`dispose` (see `_AddSheet` in `asset_detail_screen.dart`).

### mounted Check After async

```dart
await someAsyncOp();
if (!mounted) return;
setState(() { ... });
```

### Global Dialogs — Use Get.overlayContext

```dart
showGeneralDialog(context: Get.overlayContext!, ...);
// NOT: Get.context!
```

## Commands

```bash
flutter pub get
flutter analyze --no-fatal-infos   # CI gate (warnings→errors, infos OK)
flutter test                        # 90 unit/widget tests ONLY (test/) — never integration tests
flutter test test/<file>_test.dart  # single file
flutter run
flutter build apk --release
flutter build appbundle --release
flutter build web --release --base-href /WealthSync/   # GitHub Pages deploy
flutter gen-l10n                    # after editing ARB files in lib/l10n/ (l10n.yaml + generate: true)
```

**Integration tests never run under plain `flutter test`** — they only run when explicitly invoked. Manual local run (emulator-5554, live Firebase account):

```bash
# Credentials come from CI secrets; paste as --dart-define for local runs.
# CI instead runs tool/run_integration_tests.sh, which loops the files one by
# one (15m timeout each), restarts the emulator process before every file after
# the first (fresh qemu = clean host GL state, see gotcha #9), and pulls
# screenshots incrementally into build/report/parts + build/report/screenshots.
# If a file fails while the emulator's adb connection is offline, the script
# recovers the device once and retries that file; real test failures (device
# reachable) are never retried. If recovery AND a full emulator restart both
# fail, the emulator process is presumed dead and all remaining files are
# skipped fast. `generate_test_report.dart` globs integration_test/*_test.dart
# and renders any file with no JSON part as an INTERRUPTED row, so the report
# always reflects all 19 files, not just the ones that produced output.
flutter test integration_test -d emulator-5554 --no-uninstall \
  --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=... \
  --file-reporter json:build/report/integration.json
mkdir -p build/report/screenshots
adb shell run-as app.vercel.justaman045.money_control ls -1 cache/screenshots 2>/dev/null | while read f; do
  adb exec-out run-as app.vercel.justaman045.money_control cat "cache/screenshots/$f" > "build/report/screenshots/$f"
done
# --integration accepts a single file or a comma-separated list (one per
# `flutter test` invocation); each file is parsed independently.
dart run tool/generate_test_report.dart --unit=build/report/unit.json \
  --integration=build/report/integration.json \
  --screenshots=build/report/screenshots --out=build/report/report.html
```

CI (`.github/workflows/flutter_build.yml`): analyze → unit/widget test → integration test (Android emulator, live Firebase test account via `TEST_EMAIL`/`TEST_PASSWORD` secrets) → build **gated on integration_test passing** (`build`/`build_web` `needs: integration_test` — nothing ships until every test passes). On merge to `master`, CI auto-bumps `pubspec.yaml` to `2.0.<run_number>`, updates `app_version.json` + README download link, creates a signed GitHub release (`v2.0.<run_number>`), and deploys web to GitHub Pages under base-href `/WealthSync/`. Version-commit/README-commit loops are avoided by skipping the commit when the message starts with `CI:`. Every run uploads a self-contained `report.html` artifact (pass/fail per test, collapsible errors, base64 screenshots) — generated even on red runs.

## Architecture

**MVC-Service-Repository** with GetX. Package name is `money_control` (used in imports).

| Directory | Role |
|-----------|------|
| `lib/Models/` | Data classes with `fromMap`/`toMap` |
| `lib/Repositories/` | Firestore data access only |
| `lib/Services/` | Business logic (not controllers) |
| `lib/Controllers/` | GetX controllers binding services to reactive state |
| `lib/Screens/` | Widgets only; no logic |
| `lib/Components/` | Reusable widgets |
| `lib/Config/` | `AssetScreenConfig` definitions |
| `lib/Utils/` | `IconHelper`, `wealth_math.dart` |
| `lib/Platform/` | Platform abstraction stubs for 9 services (biometric, geocoding, IAP, notification, SMS, etc.) |
| `lib/l10n/` | ARB localization files (`app_en.arb` template) |
| `lib/data/` | Challenge preset seed data |
| `test/` | 9 unit/widget test files (inactivity_reminder, lent_money_model, recurring_payment_model, sms_category, upi_apps, upi_qr, wealth_data, wealth_math, widget) |
| `integration_test/` | 19 integration tests — require a live Firebase backend and are run against emulator-5554 with `TEST_EMAIL`/`TEST_PASSWORD` dart-defines (see `test_credentials.dart`). `mainCommon(isTest: true)` only skips Crashlytics/notifications. Tests: add_transaction, ai_insights, analytics_reports, app_test, budget_categories, edit_profile, full_app_e2e_tabs, full_app_e2e_transaction, goals_challenges, lent_money_split_bill, login, login_valid, receive_transaction_e2e, search_transaction, settings, subscription_flow, subscription_screen, transaction_management, wealth_assets. Helpers in `test_helpers.dart`: `launchAndSignIn`, `tapNavTab` (auto-reveals the auto-hiding bottom bar), `handleSplashAndOnboarding`, `loginIfNeeded`, `createTransaction`, `waitForHome`, `waitForGone`. |

## Integration Test Gotchas

1. **Tests need the dart-defines** — `flutter test integration_test -d emulator-5554 --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...` or auth fails with `[firebase_auth/channel-error]` ("Given String is empty or null"). `test_credentials.dart` uses `String.fromEnvironment` with empty defaults on purpose.
2. **Shared Pro account** — `wilajor863@copawoke.com` is `isPro=true`; free-path assertions (`'Budgeting'`, `'Upgrade to Pro'`, `'Monthly'`) only work against a throwaway/free account.
3. **`createTransaction` waits for the payment screen to open AND pop** — after submit the screen lingers ~700 ms for the confetti celebration before `Navigator.pop`, and 'Total Balance' is already present in the offstage home route below, so `waitForHome` alone races into the next tap.
4. **Decorative blobs must not block taps** — the balance-card gradient circles are wrapped in `IgnorePointer`; they overlap the Send/Receive buttons once the streak banner grows the card (`balance_card.dart`).
5. **`_InviteFriendsCard` listener needs an `onError`** — the `users/{email}` snapshots stream errors with permission-denied after sign-out; without the handler the settings sign-out test fails on an unhandled exception (`settings.dart`).
6. **Data-dependent analytics markers** — 'Monthly Trend' only renders with ≥2 months of data ('Current Period' otherwise), and 'Expense Breakdown' needs non-zero expenses. `analytics_insights_test.dart` seeds an expense + income first and accepts either trend title. |
7. **`flutter test` uninstalls the app after integration runs** — the `--uninstall` flag defaults to true (Flutter tool), wiping the device cache that holds the screenshots. Always pass `--no-uninstall` (CI does) so the `adb exec-out run-as ... cat` pull after the run finds them. Per-file reinstalls use `adb install -r`, so screenshots accumulate across test files while the app stays installed.
8. **`testWidgetsWithScreenshots` auto-captures screenshots** — every integration test uses the wrapper in `test_helpers.dart`; on success it writes `result_<name>.png` to `<app cache>/screenshots/`, on failure `failure_<name>.png` (error is rethrown so the test still fails). Capture is engine-first (`layer.toImage()` — no `convertFlutterSurfaceToImage()` surface swap, which is what stresses the emulator's fragile gfxstream ColorBuffer path); it falls back to `binding.takeScreenshot()` only if the engine path yields nothing. `tool/generate_test_report.dart` embeds them base64 into the single-file `report.html`; new integration tests must keep using the wrapper so their screenshots land in the report. FAIL rows with no error text are labeled **HOST LOST** — the emulator/adb connection dropped mid-test (an infra failure, never a test assertion).
9. **Emulator dies from host-GL accumulation across app launches — restart between files** — `analytics_insights_test` deterministically killed the emulator process (qemu gone; `adb -s emulator-5554 emu kill` at job end failed with `Connection refused` on TCP 5554) after ~7 min in three consecutive runs. The death is tied to the SECOND app launch: `add_transaction_test` (first file) always survives ~11 min, the second file dies ~7 min in. `-gpu guest` does NOT help (API 34 google_apis image doesn't support guest rendering — it silently falls back to host `lavapipe`). Fix: `restart_emulator()` in `tool/run_integration_tests.sh` kills qemu and boots a fresh emulator before every file after the first, so each file runs as a first app instance on clean host GL state. `recover_device()` only helps an adb wedge — after recovery fails the script tries a full restart, and only gives up (setting `EMULATOR_DEAD`, skipping remaining files fast) when the restart itself fails.

ThemeController is inline in `main.dart` (registered before any screen). Note: `PerformanceController` and `ConnectivityController` are GetX controllers but live in `lib/Services/` (not `lib/Controllers/`).

## Controller Registration (2-Phase)

**Phase 1 — `mainCommon()`** (in this order, `main.dart`): ThemeController → PrivacyController → CurrencyController → AuthController → SubscriptionController → PaymentConfigService → PerformanceController → ConnectivityController → IapService → BiometricService.

**Phase 2 — `_handleAuthChange()` after login**: TransactionController → ProfileController → AnalyticsController → BudgetController → GoalsController → LoanController → ChallengesController → LentMoneyController → RecurringPaymentController.

`BudgetController` and `AnalyticsController` call `Get.find<TransactionController>()` during init — registering them in phase 1 crashes. Screens self-register via `Get.isRegistered()` + `Get.put()` in `initState` (onboarding shows screens before phase 2).

## Transaction Sign Convention

- **Expense**: `amount = -abs(value)`, `senderId = user.uid`, `recipientId = ""`
- **Income**: `amount = +abs(value)`, `senderId = ""`, `recipientId = user.uid`
- Budget aggregation: filter `amount < 0` before `.abs()` — otherwise income triggers false over-budget alerts
- CSV import (`import_service.dart`): must NOT call `.abs()` on amounts

## Wealth / Asset System

One Firestore subcollection per asset type under `users/{userEmail}/`, plus `wealth/portfolio` summary doc.

**26 subcollections** (listed in `firestore.rules` wildcard): `fd_accounts, ppf_accounts, post_office_schemes, bonds, chit_funds, stock_holdings, sip_holdings, etf_holdings, foreign_stocks, startup_investments, pf_accounts, vpf_accounts, nps_accounts, gold_holdings, sgb_holdings, jewelry_items, crypto_holdings, reit_holdings, p2p_loans, agri_land, properties, vehicles, insurance_policies, business_assets, bnpl_entries, credit_cards`

**WealthPortfolio** (`lib/Models/wealth_data.dart`): 24 asset fields + `custom` map, `targets`, `hiddenKeys`. `totalAssets` sums all 24 + custom entries. `totalLiabilities = loans + creditCard + bnpl`.

**Dashboard** must use `streamPortfolio()` (not `getPortfolio()`) — one-shot fetch leaves amounts stale after navigating back. Confirmed in `wealth_builder.dart:61` (primary subscription in `initState`). Note: `_loadData()` (line 74) also calls `getPortfolio()` (line 89) for geo-enrichment, but the primary real-time data comes from the stream.

**Generic screen**: `AssetDetailScreen(config:)` — 22 configs in `lib/Config/asset_screen_configs.dart` (all types except the four below). Custom screens: `RealEstateDetailScreen` (properties), `VehicleDetailScreen`, `InsurancePolicyScreen`, `CreditCardDetailScreen`.

## Code Style

- `flutter_screenutil` suffixes (`.w`, `.h`, `.sp`) — no hardcoded pixels; design ref 390×844
- `CurrencyController.to.currencySymbol.value` — never `₹`
- `Exception("message")` — never `throw "message"`
- `QueryDocumentSnapshot.data()` is non-nullable (no `!` or `as Map`)
- `DocumentSnapshot.data()` is nullable (needs `?` or null check)

## SMS Classification

Primary regex must include `debited by`/`credited by` for Indian UPI messages ("debited by 86.00" has no `Rs`/`INR` prefix):

```
(?:Rs\.?|INR|MRP|Amt|Amount|debited by|credited by|by Rs\.?)\W*(\d+(?:,\d+)*(?:\.\d{1,2})?)
```

Priority: refund/cashback→credit, debited/deducted/withdrawn/spent/sent→debit, credited/deposit→credit, "received by"→debit, "received in/to/into/from"→credit, default→debit.

## Common Gotchas

1. **Stream `.limit()` on balance** — never apply. Balance sums ALL transactions.
2. **Cache invalidation after read** — always `LocalCacheService.invalidate(key)` after restoring from cache. Prevents stale `.limit()` data.
3. **Salary detection false positives** — filter EMI/loans from candidates BEFORE median/max. Check `recipientName` for exclusion keywords only (not `note`/`category`).
4. **`fromMap` Timestamp cast** — use `(map['lastUpdated'] as dynamic)?.toDate()` (works with real Timestamp and test mocks).
5. **Test values drift** — when adding asset fields, update `totalAssets` expected values in both `wealth_data_test.dart` tests and the comment sum.
6. **`compact()` formats** — `wealth_math.dart`: ≥10M (1Cr) → `"x.xCr"`, ≥100K (1L) → `"x.xL"`, ≥1K → integer `K`. So `compact(1500)` → `"2K"` and `compact(1_000_000)` → `"10.0L"` (1M is below the 1Cr threshold, not `"1.0M"`).
7. **Don't mix GetX + Flutter navigator** — `Get.dialog()` + `Navigator.pop()` + `Get.snackbar()` crashes. Use `showDialog()` + `Navigator.of(context, rootNavigator: true).pop()` + `ScaffoldMessenger.showSnackBar()`.
8. **FilePicker.saveFile() returns content:// on Android** — cannot `File(uri).writeAsString()`. Pass `bytes: Uint8List.fromList(utf8.encode(csv))`.
9. **`orderBy() as Query` is unnecessary cast** — triggers `unnecessary_cast` warning.
10. **Static cache leaks on logout** — `SmsService.resetCache()` (clears `_correctionCache`, `_historyCache`, `_rulesLoaded`) and `RecurringService.resetCache()` are both called on logout (`main.dart` + `auth_controller.dart`).
11. **Trial state race** — subscription trial flags must be set *after* Firestore confirms the write.
12. **BackdropFilter sigma** — keep sigma ≤ 4 and wrap in `RepaintBoundary`. Sigma 10 + two instances = severe scroll jank (`glass_container.dart`).
13. **Avoid ShaderMask on animated text** — renders child offscreen each frame. Use direct `TextStyle(color:)` instead (`balance_card.dart`).
14. **setState in TweenAnimationBuilder.onEnd** — triggers full subtree rebuild on every animation completion. Use `ValueNotifier` + `.value = ` instead.
15. **Cache O(n) getters** — `totalBalance` iterates all transactions. Use `Rx` + `ever` worker so the loop only runs when data actually changes (`transaction_controller.dart`).
16. **Cache Theme.of** — 13 calls per build in `analytics.dart` → cache `_cachedTheme` and `_cachedIsDark` in `build()`, restore `get isDark => _cachedIsDark`.
17. **Unchecked `jsonDecode` casts** — always check `is Map` / `is List` before `as`. Prevents crashes on corrupted cache (`category_service.dart`, `offline_queue.dart`, `sms_import_screen.dart`).
18. **Firestore JS SDK b815 corruption (web)** — after the AsyncQueue assertion the SDK is unrecoverable without a page reload; `main.dart` detects the error string and auto-reloads once via `reloadPage()` (`web_reload_web.dart`). The whole web auth flow in `main.dart` is shaped around avoiding this bug — do NOT "simplify" it: `enableNetwork()` is deferred until after login, Phase 2 controllers are registered with 500 ms delays on web, `ThemeController.resubscribe()` is re-invoked after `TransactionController` is up (with the `.get()` kept after `.snapshots()` listeners), `PaymentConfigService.startPolling()` only starts after all `.snapshots()` listeners exist, `_checkOnboardingStatus` skips the Firestore `.get()` on web, and `checkSubscriptionStatus()` is skipped on app resume. Any reordering can re-trigger the crash.

## Platform-Specific

- **Google Sign-In**: Pinned to `^6.2.2` (`pubspec.yaml`). Do not upgrade to v7+ — `signIn()` replaced with stream-based API that has a race condition.
- **UPI Payments**: Kotlin MethodChannel (`money_control/upi`), not `url_launcher`. Hard-coded package names: GPay, PhonePe, Paytm, BHIM, CRED, null (system chooser). `canLaunchUrl()` unreliable on Android 11+ — show all apps and handle `APP_NOT_FOUND` via try/catch.
- **Built-in Kotlin**: As of Flutter 3.35, plugins that apply KGP directly (`file_picker`, `firebase_storage`, `home_widget`, `share_plus`, `shared_preferences_android`, `workmanager_android`, `package_info_plus`) trigger a migration warning. Track upstream updates; no action needed until Flutter drops KGP support.
- **google-services.json**: Gitignored. CI injects from `secrets.GOOGLE_SERVICES_JSON`. For local builds, download from Firebase Console to `android/app/google-services.json`.
