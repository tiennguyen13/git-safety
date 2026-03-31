#!/usr/bin/env bash
# test/run-tests.sh — verify that all pre-commit and pre-push hooks are working
# Usage: bash test/run-tests.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

ROOT_DIR="$(git rev-parse --show-toplevel)"
HOOK="$ROOT_DIR/.git/hooks/pre-commit"

# Ensure hooks are installed
if [ ! -f "$HOOK" ]; then
  echo -e "${RED}✗ Hooks not installed. Run: bash scripts/setup-git-hooks.sh${NC}"
  exit 1
fi

# --- Helper ---
expect_blocked() {
  local TEST_NAME="$1"
  local FILE="$2"
  local CONTENT="$3"

  echo "$CONTENT" > "$FILE"
  git add --force "$FILE" 2>/dev/null

  if bash "$HOOK" 2>/dev/null; then
    echo -e "  ${RED}✗ FAIL${NC}: $TEST_NAME — hook should have blocked this but didn't"
    FAIL=$((FAIL + 1))
  else
    echo -e "  ${GREEN}✓ PASS${NC}: $TEST_NAME — correctly blocked"
    PASS=$((PASS + 1))
  fi

  git restore --staged "$FILE" 2>/dev/null || true
  rm -f "$FILE"
}

expect_allowed() {
  local TEST_NAME="$1"
  local FILE="$2"
  local CONTENT="$3"

  echo "$CONTENT" > "$FILE"
  git add --force "$FILE" 2>/dev/null

  if bash "$HOOK" 2>/dev/null; then
    echo -e "  ${GREEN}✓ PASS${NC}: $TEST_NAME — correctly allowed"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗ FAIL${NC}: $TEST_NAME — hook blocked a safe file"
    FAIL=$((FAIL + 1))
  fi

  git restore --staged "$FILE" 2>/dev/null || true
  rm -f "$FILE"
}

echo ""
echo "=== Running pre-commit hook tests ==="
echo ""

# --- Tests that should be BLOCKED ---
expect_blocked \
  ".env file commit" \
  ".env" \
  "DB_PASSWORD=super_secret_123"

expect_blocked \
  ".env.local file commit" \
  ".env.local" \
  "API_KEY=abc123"

expect_blocked \
  ".env.production file commit" \
  ".env.production" \
  "JWT_SECRET=prod-secret"

expect_blocked \
  "Private key in file" \
  "test/tmp_key.txt" \
  "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xHn/ygWep4UqGCFoSFJWnmHyMkEpjquGxwLX
-----END RSA PRIVATE KEY-----"

expect_blocked \
  "Hardcoded password in source" \
  "test/tmp_config.go" \
  'db_password = "my_super_secret_pass"'

expect_blocked \
  "Hardcoded API key in source" \
  "test/tmp_client.go" \
  'api_key = "sk-abc123verysecretkey"'

expect_blocked \
  "Hardcoded secret_key (underscore)" \
  "test/tmp_address.go" \
  'const secret_key = "zMTFf8Z4z7JGDjqTrcvtxKPPme-dzdQmbkrfdRCy_AKJ"'

expect_blocked \
  "Hardcoded secretKey (camelCase)" \
  "test/tmp_config.js" \
  'const secretKey = "my-secret-value-123"'

expect_blocked \
  "Hardcoded SECRET_KEY (all caps)" \
  "test/tmp_env.py" \
  'SECRET_KEY = "django-secret-key-abc123"'

expect_blocked \
  "Hardcoded client_secret" \
  "test/tmp_oauth.go" \
  'clientSecret := "oauth-client-secret-xyz789"'

expect_blocked \
  "Hardcoded auth_token" \
  "test/tmp_auth.go" \
  'auth_token = "bearer-token-abc123xyz"'

# --- Tests that should be ALLOWED ---
expect_allowed \
  ".env.example (template, safe)" \
  ".env.example" \
  "DB_PASSWORD=your-password-here"

expect_allowed \
  "Normal Go source file" \
  "test/tmp_safe.go" \
  'package main

func main() {
  db := connect(os.Getenv("DB_PASSWORD"))
}'

expect_allowed \
  "README with env var docs" \
  "test/tmp_readme.md" \
  "Set DB_PASSWORD env var before running."

# --- Summary ---
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
echo ""

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}Some tests failed. Check your hook installation.${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
fi
