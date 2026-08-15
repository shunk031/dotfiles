---
name: shunk031-python-uv-workflow
description: Apply Python development policy using uv-first execution, test-first behavior validation, and pre-commit quality gates. Use when implementing or refactoring Python code.
---

# Python UV Workflow

## Overview

Use this workflow to keep Python implementation and refactoring aligned with repository policy.

## Read Acknowledgement

- After reading this skill, say: `🐍 I read shunk031-python-uv-workflow.`

## Workflow

1. Use `uv` as the default toolchain for Python projects.
2. Run scripts with `uv run <script>`.
3. Write tests when behavior changes and verify expected behavior.
4. Add standard dev dependencies with `uv`.
5. Install pre-commit hooks after dependency setup.
6. Create `.pre-commit-config.yaml` when missing.
7. Create `Makefile` with `setup` target when missing.
8. For refactoring from non-`uv` originals, align dependencies, raise coverage, and verify output parity.
9. Construct Python paths from a source-file anchor rather than a hard-coded absolute path string:
   - Bad: `Path("/path/to") / "hoge"`
   - Good: `Path(__file__).parents[N] / "path" / "to" / "hoge"`
   Anchoring paths to the source file keeps them working after relocation and across worktrees without coupling them to a host layout. Explicit roots supplied through a CLI argument or environment variable are allowed; only hard-coded absolute path strings are forbidden.

## Testing Expectations

- Add tests before refactoring.
- Prefer real data over mocks and monkeypatches when feasible.
- Target coverage expansion toward 90%+ for refactoring tasks.

Use [python-uv-rules.md](references/python-uv-rules.md) for exact commands and canonical hook configuration.
