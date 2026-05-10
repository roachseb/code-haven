# ═══════════════════════════════════════════════════════════════
# Code Haven — Test Makefile
#
# Run tests locally:
#   make test           Run all unit + contract tests
#   make test-unit      Run unit tests only
#   make test-contract  Run contract tests only
#   make test-tfvars    Run tfvars generation tests
#   make test-routing   Run routing validation tests
#   make simulate       Simulate all fixtures (no TF CLI needed)
#   make simulate-plan  Simulate + terraform validate
#   make simulate-one   Test a single fixture (FIXTURE=gcp-cloud-run)
#   make validate       Run terraform validate on all fixtures
#   make test-all       Run everything (requires terraform CLI)
#
# Prerequisites:
#   - bash, jq, yq
#   - terraform (for simulate-plan, validate, test-all)
# ═══════════════════════════════════════════════════════════════

.PHONY: test test-unit test-contract test-tfvars test-routing \
        simulate simulate-plan simulate-one validate test-all \
        check-deps help

SHELL := /bin/bash

# ── Default ──────────────────────────────────────────────────
help:
	@echo ""
	@echo "Code Haven Test Suite"
	@echo "═════════════════════"
	@echo ""
	@echo "  make test            Unit + contract tests (fast, no TF CLI)"
	@echo "  make simulate        Simulate all fixtures"
	@echo "  make simulate-plan   Simulate + terraform validate"
	@echo "  make simulate-one FIXTURE=gcp-cloud-run"
	@echo "  make validate        Terraform validate all fixtures"
	@echo "  make test-all        Run everything"
	@echo ""

# ── Dependency check ─────────────────────────────────────────
check-deps:
	@command -v jq >/dev/null 2>&1 || { echo "Missing: jq"; exit 1; }
	@command -v yq >/dev/null 2>&1 || { echo "Missing: yq"; exit 1; }

check-tf:
	@command -v terraform >/dev/null 2>&1 || { echo "Missing: terraform CLI"; exit 1; }

# ── Unit Tests ───────────────────────────────────────────────
test-routing: check-deps
	@bash tests/unit/test-deploy-routing.sh

test-tfvars: check-deps
	@bash tests/unit/test-generate-tfvars.sh

test-contract: check-deps
	@bash tests/unit/test-contracts.sh

test: test-routing test-contract test-tfvars

# ── Simulation ───────────────────────────────────────────────
simulate: check-deps
	@bash tests/local/simulate-deploy.sh --all

simulate-plan: check-deps check-tf
	@bash tests/local/simulate-deploy.sh --all --plan

simulate-one: check-deps
	@if [ -z "$(FIXTURE)" ]; then \
		echo "Usage: make simulate-one FIXTURE=gcp-cloud-run"; \
		exit 1; \
	fi
	@bash tests/local/simulate-deploy.sh tests/fixtures/$(FIXTURE) --plan

# ── Integration ──────────────────────────────────────────────
validate: check-deps check-tf
	@bash tests/integration/test-tf-validate.sh

# ── Full Suite ───────────────────────────────────────────────
test-all: test simulate-plan validate
	@echo ""
	@echo "✅ All tests passed"
