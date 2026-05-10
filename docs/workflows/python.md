# Python / Django

**Workflow:** [`_build-python.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-python.yml)  
**Triggered by:** `setup.py` / `pyproject.toml` / `manage.py` / `tox.ini` / `mkdocs.yml`

## Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| `python-build` | `setup.py` / `pyproject.toml` | Builds package with `python -m build` |
| `python-test` | After build | pytest with coverage (HTML, XML, markdown summary) |
| `python-tox` | `tox.ini` / `tox.toml` | Multi-environment testing (multiple Python versions) |
| `django-test` | `manage.py` | Django test runner with database support |
| `mkdocs-build` | `mkdocs.yml` | MkDocs Material site build (artifact uploaded for Pages) |
| `python-deploy` | Tag push (`v*`) | PyPI trusted publishing via OIDC |

## Configuration

```yaml
with:
  python_version: '3.12'
```

## How testing works

Code Haven runs pytest with coverage enabled by default. It looks for tests in
standard locations (`tests/`, `test_*.py`, `*_test.py`).

**Coverage reports** are generated in three formats:

- **HTML** — uploaded as artifact, deployed to Pages
- **XML** — used by SonarQube (if configured)
- **Markdown summary** — displayed directly in the Actions run

### pytest configuration

Code Haven uses your existing pytest config. If you have a `pyproject.toml`,
`pytest.ini`, or `setup.cfg` with pytest settings, they apply automatically.

```ini title="pyproject.toml (example)"
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers -v"

[tool.coverage.run]
source = ["src"]
```

### tox

If `tox.ini` or `tox.toml` is detected, Code Haven runs tox instead of bare
pytest. This lets you test across multiple Python versions:

```ini title="tox.ini (example)"
[tox]
envlist = py310, py311, py312

[testenv]
deps = pytest
commands = pytest tests/
```

### Django

If `manage.py` exists, Code Haven uses `python manage.py test` instead of pytest.
Django settings are expected in the standard `DJANGO_SETTINGS_MODULE` environment
variable or project defaults.

## Publishing to PyPI

On tag pushes (`v*`), Code Haven publishes to PyPI using
[trusted publishing](https://docs.pypi.org/trusted-publishers/) (OIDC).
No `PYPI_TOKEN` secret needed — configure your PyPI project to trust
your GitHub repository's Actions OIDC identity.
