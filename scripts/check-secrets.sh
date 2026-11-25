#!/usr/bin/env bash
set -euo pipefail

RESULT_FILE="/tmp/deploy-guard-secrets.result"

# Patterns that suggest exposed secrets
PATTERNS=(
  'password\s*=\s*["\x27][^"\x27]{4,}'
  'api[_-]?key\s*=\s*["\x27][A-Za-z0-9]{16,}'
  'secret[_-]?key\s*=\s*["\x27][A-Za-z0-9]{16,}'
  'AKIA[0-9A-Z]{16}'
  'sk-[A-Za-z0-9]{20,}'
  'ghp_[A-Za-z0-9]{36}'
  'gho_[A-Za-z0-9]{36}'
  'glpat-[A-Za-z0-9\-]{20,}'
  'xox[bpors]-[A-Za-z0-9\-]{10,}'
)

EXCLUDE_DIRS="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=__pycache__ --exclude-dir=dist --exclude-dir=build --exclude-dir=.next"
EXCLUDE_FILES="--exclude=*.lock --exclude=package-lock.json --exclude=*.min.js --exclude=*.map"

FOUND_SECRETS=""
COUNT=0

for pattern in "${PATTERNS[@]}"; do
  # shellcheck disable=SC2086
  MATCHES=$(grep -rnEI $EXCLUDE_DIRS $EXCLUDE_FILES "$pattern" . 2>/dev/null | \
    grep -v '\.example' | \
    grep -v '\.sample' | \
    grep -v 'test' | \
    grep -v 'mock' | \
    grep -v 'fixture' | \
    grep -v 'placeholder' | \
    grep -v 'your[-_]' | \
    head -5) || true

  if [ -n "$MATCHES" ]; then
    COUNT=$((COUNT + $(echo "$MATCHES" | wc -l | tr -d ' ')))
    FOUND_SECRETS="${FOUND_SECRETS}${MATCHES}\n"
  fi
done

if [ "$COUNT" -gt 0 ]; then
  echo "FAIL" > "$RESULT_FILE"
  echo "Found $COUNT potential secret(s) in code" >> "$RESULT_FILE"
  echo "::error::Found $COUNT potential exposed secret(s) in code"
  echo -e "$FOUND_SECRETS" | head -10 | while IFS= read -r line; do
    [ -n "$line" ] && echo "::error::  $line"
  done
else
  echo "PASS" > "$RESULT_FILE"
  echo "No exposed secrets detected" >> "$RESULT_FILE"
fi
