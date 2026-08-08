#!/usr/bin/env bash
# Runs the integration-test suite one file at a time so a single hung file
# (test-body or app-connect level) can never block the rest of the suite. Each
# file gets a hard `timeout`; screenshots are pulled from the emulator after
# every file so a later failure can't lose earlier files' images. The exit code
# is non-zero if ANY file failed or was killed — the workflow gates the release
# build on this job passing.
#
# If a file fails because the emulator's adb connection dropped (gfxstream
# wedges on this headless setup), the device is recovered once and the file is
# retried, so one emulator hiccup can't cascade into "no device found" failures
# for every remaining file. Real test failures (device still reachable) are NOT
# retried — a genuine bug should not silently double its CI time.
#
# Recovery only helps an adb wedge — it can never revive a dead emulator
# PROCESS (qemu gone, port 5554 refused). If recovery fails once, the emulator
# is presumed dead and every remaining file is skipped fast (a ~2 min tail)
# instead of burning ~85 s of futile recovery per file.
#
# Credentials come from the environment (set as step env on the calling
# workflow), never interpolated into this file.
#
# Invoked as a single `bash tool/run_integration_tests.sh` line because
# reactivecircus/android-emulator-runner executes its `script:` input one line
# at a time via `/usr/bin/sh -c`, which cannot carry multi-line loops.
set -e

mkdir -p build/report/parts build/report/screenshots

# True when the emulator is reachable AND not offline ("adb: device offline"
# shows up in `adb devices` as the state "offline").
device_ok() {
  adb devices 2>/dev/null | grep -qE '^emulator-5554[[:space:]]+device$'
}

# Re-establishes the adb connection to a wedged emulator and waits for Android
# to fully boot. Returns 0 on success, 1 if the device never comes back.
recover_device() {
  echo "Recovering emulator adb connection..."
  adb reconnect 2>/dev/null || true
  sleep 3
  if ! device_ok; then
    adb kill-server 2>/dev/null || true
    adb start-server 2>/dev/null || true
  fi
  # wait-for-device can block forever on a dead emulator — bound it and let the
  # poll loop below decide whether the device actually came back.
  timeout 20 adb wait-for-device 2>/dev/null || true
  for _ in $(seq 1 30); do
    if device_ok && [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      echo "Emulator back online."
      return 0
    fi
    sleep 2
  done
  echo "Emulator did not recover."
  return 1
}

# Kills the emulator process and launches a fresh one. Host-side gfxstream/GL
# state accumulates across app launches and deterministically killed the qemu
# process at the second file (analytics_insights_test) in three consecutive CI
# runs — a fresh qemu process resets all of it so every file runs as the first
# app instance. Flags mirror the action's emulator-options in flutter_build.yml
# (plus -no-snapshot for a deterministic cold boot). Only useful when a qemu
# process actually exists to restart; on a truly dead emulator this can revive
# it, so the caller can retry the current file after a full restart.
restart_emulator() {
  echo "Restarting emulator (fresh qemu process)..."
  adb -s emulator-5554 emu kill 2>/dev/null || true
  # Wait for the old process to fully exit and release port 5554.
  for _ in $(seq 1 15); do
    if ! adb devices 2>/dev/null | grep -q '^emulator-5554'; then
      break
    fi
    sleep 2
  done
  sleep 2
  nohup /usr/local/lib/android/sdk/emulator/emulator -port 5554 -avd test \
    -no-snapshot -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim \
    -camera-back none -no-metrics -cores 4 >/tmp/emulator-restart.log 2>&1 &
  for _ in $(seq 1 45); do
    if device_ok && [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      echo "Emulator restarted and booted."
      return 0
    fi
    sleep 2
  done
  echo "Emulator restart failed."
  return 1
}

run_file() {
  local f="$1"
  local name="$2"
  timeout 15m flutter test "$f" -d emulator-5554 --no-uninstall \
    --dart-define=TEST_EMAIL="$TEST_EMAIL" \
    --dart-define=TEST_PASSWORD="$TEST_PASSWORD" \
    --file-reporter "json:build/report/parts/$name.json"
}

pull_screenshots() {
  adb shell run-as app.vercel.justaman045.money_control ls -1 cache/screenshots 2>/dev/null | while read g; do
    [ -f "build/report/screenshots/$g" ] || adb exec-out run-as app.vercel.justaman045.money_control cat "cache/screenshots/$g" > "build/report/screenshots/$g" 2>/dev/null || true
  done
  echo "--- screenshots pulled so far: $(ls build/report/screenshots 2>/dev/null | wc -l)"
}

FLUTTER_EXIT=0
EMULATOR_DEAD=0
DEAD_SINCE=""
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FIRST_FILE=1
for f in integration_test/*_test.dart; do
  name=$(basename "$f" .dart)
  if [ "$EMULATOR_DEAD" = "1" ]; then
    echo "SKIP: $name (emulator confirmed dead after $DEAD_SINCE — no recovery attempt)."
    FLUTTER_EXIT=1
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi
  # Host GL state accumulates across app launches and killed the emulator at
  # the second file in three consecutive runs — give every file after the first
  # a fresh qemu process so each runs as a first app instance. The action's
  # emulator (booted fresh before the script runs) covers the first file.
  if [ "$FIRST_FILE" = "0" ]; then
    if ! restart_emulator; then
      EMULATOR_DEAD=1
      DEAD_SINCE="$name"
      FLUTTER_EXIT=1
      echo "FAIL: $name (emulator restart failed — treating emulator as dead; remaining files will be skipped fast)."
      continue
    fi
  fi
  FIRST_FILE=0
  echo "=== Running $name ==="
  if ! run_file "$f" "$name"; then
    if device_ok; then
      # Device reachable → this is a real test failure, not emulator loss.
      FLUTTER_EXIT=1
      FAIL_COUNT=$((FAIL_COUNT + 1))
      echo "FAIL: $name (test failure, device reachable — no retry)."
    else
      echo "FAIL: $name (device offline — attempting one recovery + retry)."
      if recover_device; then
        pull_screenshots
        if run_file "$f" "$name"; then
          PASS_COUNT=$((PASS_COUNT + 1))
          echo "PASS on retry: $name"
        else
          FLUTTER_EXIT=1
          FAIL_COUNT=$((FAIL_COUNT + 1))
          echo "FAIL on retry: $name"
        fi
      elif restart_emulator; then
        pull_screenshots
        if run_file "$f" "$name"; then
          PASS_COUNT=$((PASS_COUNT + 1))
          echo "PASS on restart-retry: $name"
        else
          FLUTTER_EXIT=1
          FAIL_COUNT=$((FAIL_COUNT + 1))
          echo "FAIL on restart-retry: $name"
        fi
      else
        EMULATOR_DEAD=1
        DEAD_SINCE="$name"
        FLUTTER_EXIT=1
        echo "FAIL: $name (emulator unreachable after recovery and restart — treating emulator as dead; remaining files will be skipped fast)."
      fi
    fi
  else
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
  pull_screenshots
done

echo "=== Suite finished ==="
echo "Integration passed: $PASS_COUNT -- failed: $FAIL_COUNT -- skipped: $SKIP_COUNT"
exit $FLUTTER_EXIT
