#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Code Haven — Minimal Test Framework
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

PASS=0
FAIL=0
ERRORS=()

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    expected: ${YELLOW}${expected}${NC}"
    echo -e "    actual:   ${YELLOW}${actual}${NC}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    expected to contain: ${YELLOW}${needle}${NC}"
    echo -e "    in: ${YELLOW}${haystack:0:200}${NC}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [[ -f "$path" ]]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $desc — file not found: $path"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

assert_dir_exists() {
  local desc="$1" path="$2"
  if [[ -d "$path" ]]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $desc — dir not found: $path"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

assert_json_field() {
  local desc="$1" json_file="$2" jq_expr="$3" expected="$4"
  local actual
  actual=$(jq -r "$jq_expr" "$json_file" 2>/dev/null || echo "__JQ_ERROR__")
  assert_eq "$desc" "$expected" "$actual"
}

assert_not_empty() {
  local desc="$1" value="$2"
  if [[ -n "$value" && "$value" != "null" && "$value" != "" ]]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}✗${NC} $desc — value is empty"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

describe() {
  echo ""
  echo -e "${YELLOW}▶ $1${NC}"
}

summary() {
  echo ""
  echo "════════════════════════════════════════════"
  echo -e "  ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
  if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}Failures:${NC}"
    for err in "${ERRORS[@]}"; do
      echo -e "    ${RED}•${NC} $err"
    done
    echo "════════════════════════════════════════════"
    exit 1
  fi
  echo "════════════════════════════════════════════"
}
