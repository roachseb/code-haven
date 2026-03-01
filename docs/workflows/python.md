# Python / Django

**Workflow:** [`_build-python.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-python.yml)  
**Triggered by:** `setup.py` / `pyproject.toml` / `manage.py` / `tox.ini` / `mkdocs.yml`

## Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| `python-build` | `setup.py` / `pyproject.toml` | `python -m build` |
| `python-test` | After build | pytest + coverage (HTML, XML, markdown summary) |
| `python-tox` | `tox.ini` / `tox.toml` | Multi-environment testing |
| `django-test` | `manage.py` | Django test runner |
| `mkdocs-build` | `mkdocs.yml` | MkDocs Material site build |
| `python-deploy` | Tag push | PyPI trusted publishing |

## Configuration

```yaml
with:
  python_version: '3.12'
```
