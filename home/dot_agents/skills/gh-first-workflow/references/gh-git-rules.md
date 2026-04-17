# GH/Git Rules Reference

## Investigation Policy

- Run GitHub issue/PR investigations with `gh` before using `web`.
- Use `web` only when `gh` output is unavailable or insufficient.
- Include the URL of each investigated issue/PR in the final answer.
- Never include local absolute file paths in output. Always use repository-relative paths.

## Typical `gh` Commands

```bash
gh issue view <number> --repo <owner>/<repo>
gh pr view <number> --repo <owner>/<repo>
gh issue list --repo <owner>/<repo>
gh pr list --repo <owner>/<repo>
```

## Fallback Pattern

1. Try `gh` first.
2. Record what was missing.
3. Use `web` only for the missing information.
4. Report both the result and the source URL.

## Conventional Commit Policy

- Use Conventional Commit format for commit messages.
- Keep message shape: `<type>(<scope>): <summary>`.

Common types:

- `feat`: add or expand functionality
- `fix`: correct a defect
- `docs`: update documentation only
- `refactor`: change structure without behavior change
- `test`: add or modify tests
- `chore`: maintenance work

Examples:

```text
feat(skills): split AGENTS workflow into focused skills
fix(plan): correct todo status transition when moving to done
docs(skill): clarify gh-first fallback condition
```
