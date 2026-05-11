# Python / Django

**Workflow:** [`_build-python.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-python.yml)  
**Triggered by:** `setup.py` / `pyproject.toml` / `manage.py` / `tox.ini` / `mkdocs.yml`

## Architecture

Jobs are split by package manager — each path is self-contained, no branching:

### pip jobs (no `poetry.lock`)

| Job | Trigger | Description |
|-----|---------|-------------|
| `pip-build` | `setup.py` / `pyproject.toml` | `pip install` + `python -m build` |
| `pip-test` | After build | pytest + coverage |
| `django-pip-test` | `manage.py` | `python manage.py test` |
| `mkdocs-pip-build` | `mkdocs.yml` | MkDocs Material site build |

### Poetry jobs (`poetry.lock` present)

| Job | Trigger | Description |
|-----|---------|-------------|
| `poetry-build` | `pyproject.toml` + `poetry.lock` | `poetry install` + `poetry build` |
| `poetry-test` | After build | `poetry run pytest` + coverage |
| `django-poetry-test` | `manage.py` | `poetry run python manage.py test` |
| `mkdocs-poetry-build` | `mkdocs.yml` | `poetry run mkdocs build` |

### Shared jobs (any package manager)

| Job | Trigger | Description |
|-----|---------|-------------|
| `python-tox` | `tox.ini` / `tox.toml` | Multi-environment testing |
| `python-deploy` | Tag push (`v*`) | PyPI trusted publishing via OIDC |

## Package Manager Detection

Code Haven auto-detects your Python package manager:

| File present | Tool used | Install command |
|---|---|---|
| `poetry.lock` | Poetry | `poetry install` / `poetry build` |
| `requirements.txt` | pip | `pip install -r requirements.txt` / `python -m build` |
| Neither | pip | `python -m build` (assumes deps in `pyproject.toml` build-system) |

Only the matching set of jobs runs — never both. No configuration needed,
just commit your lock file.

## Configuration

```yaml
with:
  python_version: '3.12'
```

## Poetry

If `poetry.lock` is present, Code Haven automatically runs the Poetry job
variants. No extra flags needed.

```toml title="pyproject.toml (Poetry project)"
[tool.poetry]
name = "my-app"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "^0.115"

[tool.poetry.group.dev.dependencies]
pytest = "^8.0"
coverage = "^7.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

Poetry projects work exactly like pip projects — just commit `poetry.lock`
and Code Haven handles the rest.

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
