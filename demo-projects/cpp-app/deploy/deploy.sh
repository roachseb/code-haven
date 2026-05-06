#!/bin/bash
set -euo pipefail

APP_NAME="calculator-app"
DEPLOY_DIR="/opt/calculator-app"

echo "🚀 Deploying $APP_NAME..."

# Backup current version
if [ -f "$DEPLOY_DIR/calculator-app" ]; then
    cp "$DEPLOY_DIR/calculator-app" "$DEPLOY_DIR/calculator-app.bak"
fi

# Extract new version
tar -xzf "$DEPLOY_DIR/app.tar.gz" -C "$DEPLOY_DIR/" 2>/dev/null || true

# Make binary executable
chmod +x "$DEPLOY_DIR/calculator-app"

# Verify binary runs
if "$DEPLOY_DIR/calculator-app" --version 2>/dev/null || "$DEPLOY_DIR/calculator-app" < /dev/null; then
    echo "✅ Deployment successful — binary executes correctly"
    rm -f "$DEPLOY_DIR/calculator-app.bak"
else
    echo "❌ Binary execution failed — rolling back"
    if [ -f "$DEPLOY_DIR/calculator-app.bak" ]; then
        mv "$DEPLOY_DIR/calculator-app.bak" "$DEPLOY_DIR/calculator-app"
    fi
    exit 1
fi
