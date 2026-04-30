---
name: gh-first-workflow
description: Enforce gh-first GitHub investigation, pull request maintenance, and Conventional Commit output rules. Use when investigating GitHub issues or pull requests, creating or updating pull requests, summarizing investigation results, or preparing commit messages.
---

# GH-First Workflow

## Overview

Use this workflow to keep GitHub investigation and commit output consistent with repository policy.
For pull requests, keep the description aligned with the full current PR contents, not just the latest delta.
Validate the target repository/worktree before running `gh` so orphaned linked worktrees or wrong repository context do not poison GitHub operations.
When linked worktrees are involved, remember that staged and unstaged changes are tracked per worktree; committing in one worktree does not clean another.

## Read Acknowledgement

- After reading this skill, say: `🐙 私は gh-first-workflow を読みました。`

## Workflow

1. Before any `gh` or `git` write operation, confirm the target repository context with `git rev-parse --show-toplevel`, `git rev-parse --git-dir`, and `git status --short --branch`.
2. If the current directory may be a linked worktree, inspect `.git`. When it contains `gitdir: ...`, verify that the referenced path exists; if it does not, treat the directory as an orphaned worktree and stop using it for GitHub work.
3. In multi-repo, nested-repo, or multi-worktree situations, pin every `gh`/`git` command to the intended repository by changing `workdir` or using repo-specific flags. Do not rely on an ambient parent directory.
4. If you are using one worktree to update a branch that originated from another worktree or from the user's currently visible directory, check `git status --short --branch` in both places before declaring the work complete. Clear or explicitly report any residue in the source worktree.
5. When branch, commit, or PR work would mix with unrelated local changes, prefer a fresh task-specific `git worktree` from the default branch instead of reusing the dirty worktree.
6. Start issue/PR investigation with `gh` commands.
7. Use `web` only when `gh` cannot provide required details.
8. Collect URLs for every issue/PR that was inspected.
9. When creating a PR, write the PR description as a summary of the full PR.
10. If additional commits are pushed after PR creation, inspect the updated commits/diff with `gh` and refresh the PR description so it reflects the full current PR, not only the latest increment.
11. Include inspected URLs in the response.
12. Write commit messages in Conventional Commit format.

## Output Checklist

- State that the repository/worktree context was validated before GitHub write operations when local git state matters.
- If an orphaned or unhealthy worktree was detected, state that you switched to a healthy repository/worktree before continuing.
- If linked worktrees were involved, state whether the source worktree was also checked and whether any residual changes were cleared or intentionally left in place.
- State that `gh` was used first.
- State why `web` was used when fallback was necessary.
- Include inspected issue/PR URLs.
- When commits were added after PR creation, confirm the PR description was updated to match the full current PR.
- Keep commit subject in Conventional Commit form: `<type>(<scope>): <summary>`.
- Do NOT include local absolute file paths (e.g., `/Users/.../`, `/home/.../`) in any output. Use repository-relative paths instead.

Use [gh-git-rules.md](references/gh-git-rules.md) for command examples and commit-type guidance.
