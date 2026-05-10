#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Test Runner
# Runs all unit and integration tests
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Code Haven — Test Suite${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

TOTAL_PASS=0
TOTAL_FAIL=0

run_test() {
  local name="$1"
  local script="$2"

  echo ""
  echo -e "${YELLOW}━━━ $name ━━━${NC}"

  if bash "$script"; then
    echo -e "${GREEN}  ▶ $name PASSED${NC}"
  else
    echo -e "${RED}  ▶ $name FAILED${NC}"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
  fi
  TOTAL_PASS=$((TOTAL_PASS + 1))
}

# ── Unit Tests ────────────────────────────────────────────────
run_test "Deploy Routing" "$ROOT_DIR/tests/unit/test-deploy-routing.sh"
run_test "Generate TFVars" "$ROOT_DIR/tests/unit/test-generate-tfvars.sh"
run_test "Contract Alignment" "$ROOT_DIR/tests/unit/test-contracts.sh"

# ── Integration Tests (only if terraform is available) ────────
if command -v terraform &>/dev/null; then
  if [[ -f "$ROOT_DIR/tests/integration/test-tf-validate.sh" ]]; then
    run_test "Terraform Validate" "$ROOT_DIR/tests/integration/test-tf-validate.sh"
  fi
else
  echo ""
  echo -e "${YELLOW}⚠ Skipping integration tests (terraform CLI not found)${NC}"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
if [[ $TOTAL_FAIL -gt 0 ]]; then
  echo -e "  ${RED}$TOTAL_FAIL test suite(s) failed out of $TOTAL_PASS${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  exit 1
else
  echo -e "  ${GREEN}All $TOTAL_PASS test suite(s) passed${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
fi
