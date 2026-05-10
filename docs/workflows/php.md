# PHP

**Workflow:** [`_build-php.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-php.yml)  
**Triggered by:** `*phpunit*` files (e.g., `phpunit.xml`, `phpunit.xml.dist`)

## Jobs

| Job | Description |
|-----|-------------|
| `php-test` | Composer install + PHPUnit with xdebug coverage (HTML + Clover XML) |
| `php-twig-lint` | Symfony Twig template linting (soft-fail — reports issues but doesn't block) |

## Configuration

```yaml
with:
  php_version: '8.3'
  php_extensions: 'mbstring, xml, xdebug'
```

## How it works

1. Installs PHP with the specified version and extensions
2. Runs `composer install --no-interaction --prefer-dist`
3. Executes PHPUnit with xdebug coverage enabled
4. Uploads coverage reports (HTML + Clover XML) as artifacts
5. If `*.twig` templates exist, lints them with Symfony's twig linter

### Typical project structure

```
my-php-app/
├── phpunit.xml.dist        ← Triggers PHP detection
├── composer.json
├── composer.lock
├── src/
│   └── ...
├── tests/
│   └── ...
└── templates/
    └── *.twig              ← Triggers Twig lint
```
