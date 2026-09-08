---
paths: **/*.py
---

When using this rule, include the 🐍 emoji in your response.

## Using `uv`

- For Python projects, always use `uv` unless instructed otherwise.
- Whenever you write code, also write tests and verify that it behaves as intended.
- Run scripts with `uv run <script>`.

## Using `pyright-lsp`

- If `pyright-lsp` is installed, use it for static analysis.
- If `pyright-lsp` is not installed, recommend installing it.

## Exploratory Debugging

- Use `uv` to run temporary code, for example, `uv run python -c "..."`.
- To temporarily install and try a library that is not a project dependency, use `uv run --with <library> python -c "..."`.

## Command-Line Parsers

- When parsing command-line arguments with `argparse`, format options by joining words with hyphens, such as `--this-is-option`.
