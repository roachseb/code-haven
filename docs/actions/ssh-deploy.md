# SSH Deploy

**Action:** [`actions/ssh-deploy`](https://github.com/code-haven/code-haven/tree/main/actions/ssh-deploy)

## Overview

The SSH Deploy composite action securely connects to any remote machine and executes a project-defined deployment script. It supports:

- Artifact transfer (binaries, archives, containers)
- Environment file injection
- Pre/post deployment hooks
- Health check verification
- Deployment summary in GitHub Step Summary

## Use Cases

- Deploy to bare-metal servers
- Deploy to cloud VMs (GCP Compute Engine, AWS EC2, Azure VMs)
- Deploy to VPS providers (DigitalOcean, Hetzner, Linode)
- Deploy to on-premise infrastructure
- Deploy C/C++ compiled binaries to edge devices

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `host` | ✅ | — | Target hostname or IP |
| `user` | ✅ | `deploy` | SSH username |
| `ssh_key` | ✅ | — | Private SSH key (secret) |
| `port` | No | `22` | SSH port |
| `deploy_script` | No | `deploy/deploy.sh` | Deployment script path (in repo) |
| `deploy_path` | No | `/opt/app` | Remote deployment directory |
| `pre_deploy_commands` | No | — | Commands to run before deploy |
| `post_deploy_commands` | No | — | Commands after deploy (health check) |
| `artifact_path` | No | — | Local artifact to transfer |
| `known_hosts` | No | — | SSH known_hosts for host verification |
| `environment_file` | No | — | .env file to transfer |
| `transfer_extra_files` | No | — | Additional files (space-separated) |
| `timeout` | No | `30` | SSH connection timeout (seconds) |

## Usage

### Basic deployment

```yaml
- uses: code-haven/code-haven/actions/ssh-deploy@main
  with:
    host: ${{ secrets.DEPLOY_HOST }}
    user: deploy
    ssh_key: ${{ secrets.DEPLOY_SSH_KEY }}
    deploy_script: deploy/deploy.sh
    artifact_path: ./dist/app.tar.gz
```

### With health check and known hosts

```yaml
- uses: code-haven/code-haven/actions/ssh-deploy@main
  with:
    host: ${{ secrets.DEPLOY_HOST }}
    user: deploy
    ssh_key: ${{ secrets.DEPLOY_SSH_KEY }}
    port: '2222'
    deploy_script: deploy/deploy.sh
    deploy_path: /opt/my-service
    artifact_path: ./build/my-app
    known_hosts: ${{ secrets.KNOWN_HOSTS }}
    pre_deploy_commands: 'sudo systemctl stop my-app && cp -r /opt/my-service /opt/my-service.bak'
    post_deploy_commands: 'curl -sf http://localhost:8080/health || (sudo systemctl start my-app.bak && exit 1)'
```

### C++ binary deployment

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: |
          cmake -B build -DCMAKE_BUILD_TYPE=Release
          cmake --build build
          tar -czf app.tar.gz -C build my-app
      - uses: actions/upload-artifact@v4
        with:
          name: cpp-binary
          path: app.tar.gz

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: cpp-binary
      - uses: code-haven/code-haven/actions/ssh-deploy@main
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          user: deploy
          ssh_key: ${{ secrets.DEPLOY_SSH_KEY }}
          deploy_script: deploy/deploy.sh
          artifact_path: ./app.tar.gz
          deploy_path: /opt/my-app
          known_hosts: ${{ secrets.KNOWN_HOSTS }}
```

## Project Deploy Script Convention

Projects should include their deployment logic in `deploy/`:

```
my-project/
├── deploy/
│   ├── deploy.sh          # Main deployment script
│   ├── rollback.sh        # Rollback on failure
│   └── health-check.sh    # Post-deploy verification
├── src/
└── ...
```

### Example `deploy/deploy.sh`

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="my-app"
DEPLOY_DIR="/opt/my-app"
BACKUP_DIR="/opt/my-app.bak"

echo "🚀 Deploying $APP_NAME..."

# Backup current version
if [ -d "$DEPLOY_DIR/current" ]; then
  cp -r "$DEPLOY_DIR/current" "$BACKUP_DIR"
fi

# Extract new version
mkdir -p "$DEPLOY_DIR/current"
tar -xzf "$DEPLOY_DIR/app.tar.gz" -C "$DEPLOY_DIR/current/"

# Restart service
sudo systemctl restart "$APP_NAME"

# Wait for service to be ready
sleep 5

# Health check
if curl -sf http://localhost:8080/health > /dev/null; then
  echo "✅ Deployment successful"
  rm -rf "$BACKUP_DIR"
else
  echo "❌ Health check failed — rolling back..."
  rm -rf "$DEPLOY_DIR/current"
  mv "$BACKUP_DIR" "$DEPLOY_DIR/current"
  sudo systemctl restart "$APP_NAME"
  exit 1
fi
```

## Security Considerations

!!! warning "SSH Key Management"
    - Store SSH private keys as GitHub Secrets (never in code)
    - Use dedicated deploy user with minimal permissions
    - Prefer `known_hosts` over disabling host key verification
    - Rotate SSH keys regularly
    - Consider using short-lived SSH certificates for production

!!! tip "Using known_hosts"
    Generate your known_hosts entry:
    ```bash
    ssh-keyscan -H your-server.example.com
    ```
    Store the output as a GitHub Secret (`KNOWN_HOSTS`) for secure host verification.

## Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `DEPLOY_HOST` | Yes | Target server hostname/IP |
| `DEPLOY_SSH_KEY` | Yes | SSH private key for authentication |
| `KNOWN_HOSTS` | Recommended | SSH known_hosts for host verification |
| `DEPLOY_USER` | No | SSH username (if not hardcoded) |
