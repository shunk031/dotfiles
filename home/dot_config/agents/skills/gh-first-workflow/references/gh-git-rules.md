# GH/Git Rules Reference

## Investigation Policy

- Validate the target repository/worktree before GitHub write operations that depend on local git state.
- Run GitHub issue/PR investigations with `gh` before using `web`.
- Use `web` only when `gh` output is unavailable or insufficient.
- Include the URL of each investigated issue/PR in the final answer.
- Never include local absolute file paths in output. Always use repository-relative paths.

## Repository/Worktree Health Gate

Run these checks before branch/commit/PR work:

```bash
git rev-parse --show-toplevel
git rev-parse --git-dir
git status --short --branch
```

If the directory may be a linked worktree, inspect `.git` as well:

```bash
cat .git
```

Interpretation:

- If `git rev-parse` or `git status` fails with `fatal: not a git repository`, do not continue with `gh` from that directory.
- If `.git` contains `gitdir: <path>` and that path does not exist, the directory is an orphaned linked worktree.
- When a worktree looks suspicious, confirm the current path from a healthy canonical repo:

```bash
git -C <canonical-repo> worktree list --porcelain
```

Safe response:

- Switch to a healthy repository/worktree before continuing.
- Recreate the task worktree from the canonical repo if needed.
- In nested-repo or sibling-worktree layouts, run commands from the intended repo/worktree instead of a parent directory.

## Typical `gh` Commands

```bash
gh issue view <number> --repo <owner>/<repo>
gh pr view <number> --repo <owner>/<repo>
gh issue list --repo <owner>/<repo>
gh pr list --repo <owner>/<repo>
```

When local git context matters, prefer an explicit target repo/worktree:

```bash
git -C <repo> status --short --branch
git -C <repo> rev-parse --show-toplevel
(cd <repo> && gh pr create ...)
```

## Fallback Pattern

1. Try `gh` first.
2. Record what was missing.
3. Use `web` only for the missing information.
4. Report both the result and the source URL.

## Dirty Worktree Pattern

1. Check whether the current worktree already contains unrelated staged, unstaged, or untracked changes.
2. If yes, create or switch to a fresh task-specific `git worktree` from the default branch.
3. Apply only the task-relevant changes there.
4. Keep the PR description aligned with the full PR after every additional push.

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
