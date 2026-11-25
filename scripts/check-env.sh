#!/usr/bin/env bash
set -euo pipefail

RESULT_FILE="/tmp/deploy-guard-env.result"
ENV_EXAMPLE="${1:-.env.example}"

if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "PASS" > "$RESULT_FILE"
  echo "No $ENV_EXAMPLE found — skipping env check" >> "$RESULT_FILE"
  echo "::notice::No $ENV_EXAMPLE found — skipping env var check"
  exit 0
fi

# Extract variable names from .env.example
EXPECTED_VARS=$(grep -E '^[A-Z_][A-Z0-9_]*=' "$ENV_EXAMPLE" | cut -d= -f1 | sort -u)

if [ -z "$EXPECTED_VARS" ]; then
  echo "PASS" > "$RESULT_FILE"
  echo "No variables defined in $ENV_EXAMPLE" >> "$RESULT_FILE"
  exit 0
fi

# Search for references in code (excluding node_modules, .git, vendor, etc.)
MISSING=""
FOUND=0
TOTAL=0

for var in $EXPECTED_VARS; do
  TOTAL=$((TOTAL + 1))
  # Check if the var is referenced anywhere in the codebase
  if grep -rq --include='*.py' --include='*.ts' --include='*.js' --include='*.tsx' --include='*.jsx' --include='*.go' --include='*.rs' --include='*.yml' --include='*.yaml' --include='*.toml' \
     --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=__pycache__ \
     "$var" . 2>/dev/null; then
    FOUND=$((FOUND + 1))
  else
    MISSING="${MISSING}${var} "
  fi
done

if [ -n "$MISSING" ]; then
  echo "WARN" > "$RESULT_FILE"
  echo "$FOUND/$TOTAL vars referenced. Unreferenced: $MISSING" >> "$RESULT_FILE"
  echo "::warning::Unreferenced env vars: $MISSING"
else
  echo "PASS" > "$RESULT_FILE"
  echo "All $TOTAL env vars from $ENV_EXAMPLE are referenced in code" >> "$RESULT_FILE"
fi
