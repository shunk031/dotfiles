# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read the project-level AGENTS.md for shunk031/dotfiles.`

## Repository Context

- Tooling: This repository is managed with [`chezmoi`](https://www.chezmoi.io/) ([GitHub](https://github.com/twpayne/chezmoi)).
- Public source: Files under `home/` are the public source state and are applied by `chezmoi` into the user's `$HOME` directory.
- Private source: Private dotfiles are managed separately from `~/.local/share/chezmoi-private` with config at `~/.config/chezmoi-private/chezmoi.yaml`.
- Management boundary: Treat the public `home/` tree and the private `chezmoi` source/config as separate management domains.
- Agent skills: `home/dot_config/exact_agents/skills/*` is ignored by default because global skill installers write through symlinked runtime paths. When adding a repo-managed skill, add an explicit `.gitignore` allowlist entry for that skill.

## Comment Policy

- Comment language: When adding or updating comments for shell scripts or shell-based executables, always write them in English using shdoc-compatible format.

## Git / PR Workflow

- Dirty worktree: When you are asked to create a branch, commit, or pull request and the current worktree contains unrelated staged, unstaged, or untracked changes, prefer creating a separate `git worktree` from the default branch.
- Change isolation: In that separate `git worktree`, apply only the changes relevant to the current task and do not mix unrelated changes into the branch or pull request.
- Worktree priority: Only prioritize the current branch or worktree when the user explicitly asks you to work there.
- Post-push CI: After pushing to GitHub, always check the GitHub Actions CI results. If CI fails, investigate the failure, fix the issue, push again, and repeat until all CI checks pass.
- PR language: Always write pull request titles and descriptions in English.

## Test Policy

- Local bats: Do not run `bats` tests locally.
- CI validation: When you need to validate `bats` results, push to GitHub, let GitHub Actions CI run, and check the results there.
