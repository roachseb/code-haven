# PHP

**Workflow:** [`_build-php.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-php.yml)  
**Triggered by:** `*phpunit*` files

## Jobs

| Job | Description |
|-----|-------------|
| `php-test` | Composer install + PHPUnit with xdebug coverage |
| `php-twig-lint` | Symfony Twig template linting (soft-fail) |

## Configuration

```yaml
with:
  php_version: '8.3'
  php_extensions: 'mbstring, xml, xdebug'
```
