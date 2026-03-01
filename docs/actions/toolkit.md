# Toolkit Action

**Path:** `actions/toolkit/action.yml`

Initializes the CI environment — install CA certificates, configure debug logging,
and run optional post-init scripts.

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
| `debug` | No | `false` | Enable debug logging |
| `custom_ca_certs` | No | — | PEM-encoded CA certificates |
| `post_init_script` | No | — | Script to run after init |
