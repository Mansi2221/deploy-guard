#!/usr/bin/env bash
set -euo pipefail

RESULT_FILE="/tmp/deploy-guard-docker.result"
DOCKERFILE="${1}"

# Auto-detect Dockerfile if not specified
if [ -z "$DOCKERFILE" ]; then
  if [ -f "Dockerfile" ]; then
    DOCKERFILE="Dockerfile"
  elif [ -f "docker/Dockerfile" ]; then
    DOCKERFILE="docker/Dockerfile"
  else
    echo "PASS" > "$RESULT_FILE"
    echo "No Dockerfile found — skipping" >> "$RESULT_FILE"
    echo "::notice::No Dockerfile found — skipping Docker check"
    exit 0
  fi
fi

if [ ! -f "$DOCKERFILE" ]; then
  echo "WARN" > "$RESULT_FILE"
  echo "Specified Dockerfile not found: $DOCKERFILE" >> "$RESULT_FILE"
  echo "::warning::Specified Dockerfile not found: $DOCKERFILE"
  exit 0
fi

ISSUES=""
WARNINGS=0
FAILURES=0

# Check: running as root (no USER instruction)
if ! grep -qiE '^USER\s' "$DOCKERFILE"; then
  ISSUES="${ISSUES}No USER instruction (runs as root). "
  WARNINGS=$((WARNINGS + 1))
fi

# Check: no HEALTHCHECK
if ! grep -qiE '^HEALTHCHECK\s' "$DOCKERFILE"; then
  ISSUES="${ISSUES}No HEALTHCHECK defined. "
  WARNINGS=$((WARNINGS + 1))
fi

# Check: using latest tag
if grep -qE 'FROM\s+\S+:latest' "$DOCKERFILE"; then
  ISSUES="${ISSUES}Uses :latest tag (not reproducible). "
  WARNINGS=$((WARNINGS + 1))
fi

# Check: COPY or ADD of .env or secrets
if grep -qE '(COPY|ADD)\s+.*\.(env|pem|key|cert)\b' "$DOCKERFILE"; then
  ISSUES="${ISSUES}Copies sensitive files (.env/.pem/.key). "
  FAILURES=$((FAILURES + 1))
fi

# Check: no .dockerignore
if [ ! -f ".dockerignore" ]; then
  ISSUES="${ISSUES}No .dockerignore file. "
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL" > "$RESULT_FILE"
  echo "$ISSUES" >> "$RESULT_FILE"
  echo "::error::Dockerfile issues: $ISSUES"
elif [ "$WARNINGS" -gt 0 ]; then
  echo "WARN" > "$RESULT_FILE"
  echo "$WARNINGS warning(s): $ISSUES" >> "$RESULT_FILE"
  echo "::warning::Dockerfile warnings: $ISSUES"
else
  echo "PASS" > "$RESULT_FILE"
  echo "Dockerfile looks good" >> "$RESULT_FILE"
fi
