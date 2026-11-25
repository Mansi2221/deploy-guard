#!/usr/bin/env bash
set -euo pipefail

RESULT_FILE="/tmp/deploy-guard-ci.result"

HAS_GHA=false
HAS_OTHER_CI=false
DETAILS=""

# Check for GitHub Actions
if [ -d ".github/workflows" ] && ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | head -1 > /dev/null; then
  HAS_GHA=true
  WF_COUNT=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null | wc -l | tr -d ' ')
  DETAILS="GitHub Actions: $WF_COUNT workflow(s). "
fi

# Check for other CI systems
if [ -f ".gitlab-ci.yml" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}GitLab CI found. "
fi

if [ -f "Jenkinsfile" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}Jenkinsfile found. "
fi

if [ -f ".circleci/config.yml" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}CircleCI found. "
fi

if [ -f ".travis.yml" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}Travis CI found. "
fi

if [ -f "azure-pipelines.yml" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}Azure Pipelines found. "
fi

if [ -f "bitbucket-pipelines.yml" ]; then
  HAS_OTHER_CI=true
  DETAILS="${DETAILS}Bitbucket Pipelines found. "
fi

if $HAS_GHA || $HAS_OTHER_CI; then
  echo "PASS" > "$RESULT_FILE"
  echo "$DETAILS" >> "$RESULT_FILE"
else
  echo "FAIL" > "$RESULT_FILE"
  echo "No CI/CD pipeline found" >> "$RESULT_FILE"
  echo "::error::No CI/CD pipeline detected. Add a GitHub Actions workflow or other CI config."
fi
