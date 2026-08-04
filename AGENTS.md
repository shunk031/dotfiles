# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read the project-level AGENTS.md for shunk031/dotfiles.`

## Repository Context

- Tooling: This repository is managed with [`chezmoi`](https://www.chezmoi.io/) ([GitHub](https://github.com/twpayne/chezmoi)).
- Public source: Files under `home/` are the public source state and are applied by `chezmoi` into the user's `$HOME` directory.
- Private source: Private dotfiles are managed separately from `~/.local/share/chezmoi-private` with config at `~/.config/chezmoi-private/chezmoi.yaml`.
- Management boundary: Treat the public `home/` tree and the private `chezmoi` source/config as separate management domains.
- Codex boundary: This repo manages the Codex CLI, shared guidance, `~/.codex/AGENTS.md`, and `~/.codex/agents`; `dotfiles-private` manages `~/.codex/config.toml`, private profiles, credentials, and internal launchers.
- Agent skills: `~/.agents/skills` is a real directory (the shared skills pool); repo-managed skills live in `home/dot_config/exact_agents/skills/<name>/` and are exposed there through one `home/exact_dot_agents/skills/symlink_<name>.tmpl` per skill. Gemini receives the same repo-managed skills through one `home/dot_gemini/config/skills/symlink_<name>.tmpl` per skill, not a whole-directory adapter. `~/.claude/skills` is a real, Claude-only directory so `npx skills add --agent claude-code` and similar installers can write generated skills without touching the chezmoi source tree. A `run_after` script (`home/.chezmoiscripts/common/run_after_90-link-shared-skills.sh.tmpl`) links every pool entry into Claude's skills directory on every `chezmoi apply`, without overwriting locally installed (non-symlink) entries. To make an installer-added skill repo-managed, move its directory into `home/dot_config/exact_agents/skills/` and add matching per-skill symlink templates for the shared pool and Gemini.

## Comment Policy

- Comment language: When adding or updating comments for shell scripts or shell-based executables, always write them in English using shdoc-compatible format.

## mise Bootstrap Compatibility

- Compatibility floor: Treat the top-level `min_version` in `home/dot_mise/config.toml` as the lowest mise version supported by the repository, not as the desired installed version. New machines install this exact version, while existing newer installations must not be downgraded.
- Renovate ownership: Let Renovate manage versions under `[tools]`, but do not configure Renovate to raise `min_version` merely because a new mise release exists.
- Atomic updates: Raise `min_version` only in the same pull request as a tool or configuration change that requires newer mise behavior. Record the requirement in the pull request description.
- Failure handling: When a Renovate tool update fails with the compatibility-floor version, determine the minimum mise release that supports the update and change `min_version` in that Renovate pull request.
- Fresh-install validation: Changes to `home/dot_mise/config.toml`, `install/common/mise.sh`, or the mise `run_once` and `run_after` scripts must run both Ubuntu and macOS setup workflows. These workflows must install the configured `min_version` on a clean runner and complete `mise install`.
- Avoiding workarounds: Do not replace the compatibility floor with periodic bumps, an unpinned `latest` bootstrap, or automerge whose only purpose is hiding recurring mise update pull requests.

## Git / PR Workflow

- Default branch read-only: When the current checkout is `main` or the repository default branch, treat repo-tracked files as read-only and create a task-specific worktree from the default branch before any edit, commit, or push work, even when the worktree is clean.
- Dirty worktree: When you are asked to create a branch, commit, or pull request and the current worktree contains unrelated staged, unstaged, or untracked changes, create a separate task-specific worktree from the default branch.
- Worktree tooling: Create task worktrees with [`gwq`](https://github.com/d-kuro/gwq): run `gwq add -b <task-branch>` from the default branch checkout, then move there with `cd "$(gwq get <task-branch>)"`. In `gwq add [branch] [path]`, the second positional argument is the destination path, not a base ref, so do not pass `origin/main` there. If the new worktree must start from the latest `origin/main`, run `git fetch origin main` first, create the worktree with `gwq add -b <task-branch>`, move into it, and then run `git merge --ff-only origin/main`. Fall back to plain `git worktree add` only when `gwq` is unavailable.
- Change isolation: In that separate worktree, apply only the changes relevant to the current task and do not mix unrelated changes into the branch or pull request.
- Worktree priority: Only prioritize the current branch or worktree when the user explicitly asks you to work there.
- Commit messages: Use the Conventional Commits format `<type>(<scope>): <summary>` with a lowercase, imperative summary (see <https://www.conventionalcommits.org/en/v1.0.0/>).
- Post-push CI: After pushing to GitHub, always check the GitHub Actions CI results. If CI fails, investigate the failure, fix the issue, push again, and repeat until all CI checks pass.
- PR language: Always write pull request titles and descriptions in English.

## Test Policy

- Local bats: Do not run `bats` tests locally.
- CI validation: When you need to validate `bats` results, push to GitHub, let GitHub Actions CI run, and check the results there.
