#!/bin/bash
# Reconstruct the exact Keyboop 0.4.10 words_ru.json from repository-local chunks.
# Source blob: iffuno/keyboop@fb9bdde4eb8f13a486974cf102a8bec9d607e5d2
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
PARTS="$ROOT/.upstream-baseline/words_ru"
OUT="$ROOT/Sources/Keyboop/Resources/words_ru.json"
TMP="$OUT.tmp.$$"
EXPECTED_BYTES=3899830
EXPECTED_GIT_BLOB=c059e65604324434b110112bdfdca94125372e48

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

mkdir -p "$(dirname "$OUT")"
cat "$PARTS"/part-* > "$TMP"

ACTUAL_BYTES="$(wc -c < "$TMP" | tr -d '[:space:]')"
if [ "$ACTUAL_BYTES" != "$EXPECTED_BYTES" ]; then
  echo "✗ words_ru.json reconstruction size mismatch: $ACTUAL_BYTES != $EXPECTED_BYTES" >&2
  exit 1
fi

# Git is guaranteed on GitHub Actions runners. Locally it is optional: the user's Mac must not
# require Xcode CLT merely to run Keyboop Lite.
if command -v git >/dev/null 2>&1; then
  ACTUAL_BLOB="$(git hash-object "$TMP")"
  if [ "$ACTUAL_BLOB" != "$EXPECTED_GIT_BLOB" ]; then
    echo "✗ words_ru.json reconstruction hash mismatch: $ACTUAL_BLOB != $EXPECTED_GIT_BLOB" >&2
    exit 1
  fi
fi

mv "$TMP" "$OUT"
trap - EXIT
echo "✓ restored pinned words_ru.json ($EXPECTED_BYTES bytes)"
