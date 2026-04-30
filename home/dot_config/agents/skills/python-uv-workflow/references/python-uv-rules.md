# Python UV Rules Reference

## Base Policy

- Use `uv` by default for Python projects.
- Write tests for behavior-impacting changes.
- Run scripts with `uv run <script>`.

## Dev Dependencies

```bash
uv add --group dev ruff pytest pytest-cov mypy ty vulture pre-commit
```

Install hooks:

```bash
pre-commit install
```

## Required `.pre-commit-config.yaml` Template

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-added-large-files

  - repo: https://github.com/jendrikseipp/vulture
    hooks:
      - id: vulture

  - repo: local
    hooks:
      - id: ruff
        name: ruff (uv)
        entry: uv run ruff check --fix --exit-non-zero-on-fix
        language: system
        types_or: [python, pyi]

      - id: ruff-format
        name: ruff format (uv)
        entry: uv run ruff format
        language: system
        types_or: [python, pyi]

      - id: pytest
        name: pytest (uv)
        entry: uv run pytest -vsx --cov=<package>
        language: system
        pass_filenames: false
```

## Required `Makefile` Target (when missing)

```make
setup:
	uv sync
	pre-commit install
```

## Exploratory Debugging

```bash
uv run python -c "..."
uv run --with <library> python -c "..."
```

## Refactoring from Original Implementation

1. Move workflow to `uv` if not already using it.
2. Add original dependencies as needed:
   `uv add --optional original-impl <module>`.
3. Add tests if missing and measure with `pytest-cov`.
4. Expand tests toward at least 90% coverage.
5. Prefer small real datasets described in project docs.
6. Compare original and refactored outputs for parity.
