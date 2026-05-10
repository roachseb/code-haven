# Toolkit Action

**Path:** `actions/toolkit/action.yml`

Initializes the CI environment — installs CA certificates, configures debug logging,
and runs optional post-init scripts. This action runs at the start of every build
job automatically.

## Usage

```yaml
steps:
  - uses: code-haven/code-haven/actions/toolkit@main
    with:
      debug: 'true'
      custom_ca_certs: ${{ secrets.CA_BUNDLE }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `debug` | No | `false` | Enable debug logging (prints env vars, tool versions) |
| `custom_ca_certs` | No | — | PEM-encoded CA certificates to install system-wide |
| `post_init_script` | No | — | Path to a shell script to run after initialization |

## Custom CA certificates

If your organization uses a private CA (common in enterprise/defense environments),
pass the PEM bundle as a secret:

```yaml
- uses: code-haven/code-haven/actions/toolkit@main
  with:
    custom_ca_certs: ${{ secrets.CA_BUNDLE }}
```

The certificates are installed into the system trust store so all tools (curl, npm,
pip, Maven, Docker, etc.) trust your internal services automatically.

## Post-init scripts

Run a custom script after environment initialization. Useful for setting up
tool-specific configuration, environment variables, or downloading internal tools.

```yaml
- uses: code-haven/code-haven/actions/toolkit@main
  with:
    post_init_script: '.ci/setup.sh'
```

```bash title=".ci/setup.sh (example)"
#!/usr/bin/env bash
# Install internal CLI tool
curl -sL https://internal.example.com/cli/install.sh | bash

# Set organization-wide environment variables
echo "ORG_REGISTRY=registry.example.com" >> "$GITHUB_ENV"
```

## Debug mode

When `debug: 'true'`, the toolkit prints:

- All environment variables (secrets are masked)
- Installed tool versions (Java, Node, Python, Go, etc.)
- Disk space and runner hardware info
- Network connectivity checks
