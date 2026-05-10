# ── Code Haven Segmented Mode ──────────────────────────────────
# Copy these files into your project's .github/workflows/ directory.
# Each workflow runs independently with its own visibility in GitHub Actions.
#
# Required files (copy all):
#   build.yml      → Compiles code, runs unit tests
#   security.yml   → SAST, secrets, dependency scanning
#   quality.yml    → Linting, metrics, link checks
#
# Optional files (copy if needed):
#   test.yml       → End-to-end tests (Cypress/Playwright/Hurl)
#   deploy.yml     → Docker + Helm + Intent-based deploy
#   pages.yml      → GitHub Pages documentation
#   release.yml    → Tag-triggered releases
#
# ─── How it works ─────────────────────────────────────────────
#
# Each file calls a single Code Haven orchestrator.
# Detection is automatic — no disable flags needed.
# If your project doesn't use a feature (e.g., no Dockerfile),
# that workflow completes instantly (~5s) with a green check.
#
# ─── GitHub Actions sidebar result ────────────────────────────
#
#   🏗️ Build       ✓  (detected Java → ran Maven build + tests)
#   🔒 Security    ✓  (ran Gitleaks + CodeQL + OSV)
#   📊 Quality     ✓  (ran linting + metrics)
#   🧪 Test        —  (no e2e config found → skipped)
#   🚀 Deploy      ✓  (built Docker image, deployed to dev)
#   📖 Pages       ✓  (deployed coverage report)
#
# ─── Comparison ───────────────────────────────────────────────
#
# Unified mode (1 file, current default):
#   + Single file, minimal setup
#   - One massive workflow graph with 17 nodes
#   - Must declare disable flags for unused stacks
#
# Segmented mode (these templates):
#   + Each concern has isolated visibility and history
#   + No disable flags — detection handles everything
#   + Click "Security" to see only security results
#   - Multiple small files (7 lines each)
#   - Deploy ordering via workflow_run (default-branch only)
#
# ─── Deploy ordering ──────────────────────────────────────────
#
# On PRs: Build, Security, Quality all run in parallel (no deploy on PRs)
# On main: Deploy triggers after Build completes (via workflow_run)
# On tags: Release triggers independently
#
