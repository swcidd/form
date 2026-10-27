#!/usr/bin/env bash
#
# The gate: format, analyze, the whole suite.
#
# Kept as a script rather than a hosted workflow so it needs no account, no
# runner and no network — it runs the same three commands the README lists, in
# the same order, and stops at the first one that fails.
#
#   ./tool/check.sh
#
# `.githooks/pre-push` calls it, so a push cannot land a red tree:
#
#   git config core.hooksPath .githooks

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

# A shell started outside a login session often has no Flutter on PATH.
if ! command -v flutter >/dev/null 2>&1; then
  for candidate in "${FLUTTER_ROOT:-}" "$HOME/develop/flutter" /usr/lib/flutter; do
    if [ -n "$candidate" ] && [ -x "$candidate/bin/flutter" ]; then
      export PATH="$candidate/bin:$PATH"
      break
    fi
  done
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "check: flutter is not on PATH (set FLUTTER_ROOT or add it)" >&2
  exit 127
fi

echo "==> format"
dart format --output=none --set-exit-if-changed lib test tool

echo "==> analyze"
flutter analyze

echo "==> test"
flutter test

echo "==> all checks passed"
