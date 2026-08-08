#!/usr/bin/env bash
# Runs the integration-test suite one file at a time so a single hung file
# (test-body or app-connect level) can never block the rest of the suite. Each
# file gets a hard `timeout`; screenshots are pulled from the emulator after
# every file so a later failure can't lose earlier files' images. The exit code
# is non-zero if ANY file failed or was killed — the workflow gates the release
# build on this job passing.
#
# Credentials come from the environment (set as step env on the calling
# workflow), never interpolated into this file.
#
# Invoked as a single `bash tool/run_integration_tests.sh` line because
# reactivecircus/android-emulator-runner executes its `script:` input one line
# at a time via `/usr/bin/sh -c`, which cannot carry multi-line loops.
set -e

mkdir -p build/report/parts build/report/screenshots

FLUTTER_EXIT=0
for f in integration_test/*_test.dart; do
  name=$(basename "$f" .dart)
  echo "=== Running $name ==="
  timeout 15m flutter test "$f" -d emulator-5554 --no-uninstall \
    --dart-define=TEST_EMAIL="$TEST_EMAIL" \
    --dart-define=TEST_PASSWORD="$TEST_PASSWORD" \
    --file-reporter "json:build/report/parts/$name.json" \
    || FLUTTER_EXIT=$?
  adb shell run-as app.vercel.justaman045.money_control ls -1 cache/screenshots 2>/dev/null | while read g; do
    [ -f "build/report/screenshots/$g" ] || adb exec-out run-as app.vercel.justaman045.money_control cat "cache/screenshots/$g" > "build/report/screenshots/$g" 2>/dev/null || true
  done
  echo "--- screenshots pulled so far: $(ls build/report/screenshots 2>/dev/null | wc -l)"
done

exit $FLUTTER_EXIT
