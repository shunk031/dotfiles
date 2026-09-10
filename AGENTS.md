# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read the project-level AGENTS.md for shunk031/dotfiles.`

## Repository Context

- Tooling: This repository is managed with [`chezmoi`](https://www.chezmoi.io/) ([GitHub](https://github.com/twpayne/chezmoi)).
- Public source: Files under `home/` are the public source state and are applied by `chezmoi` into the user's `$HOME` directory.
- Private source: Private dotfiles are managed separately from `~/.local/share/chezmoi-private` with config at `~/.config/chezmoi-private/chezmoi.yaml`.
- Management boundary: Treat the public `home/` tree and the private `chezmoi` source/config as separate management domains.
- Codex boundary: This repo manages the Codex CLI, shared guidance, `~/.codex/AGENTS.md`, and `~/.codex/agents`; `dotfiles-private` manages `~/.codex/config.toml`, private profiles, credentials, and internal launchers.

## Skills

- Skill content is not in this repository. Public skills live in [shunk031/skills](https://github.com/shunk031/skills) and are installed through one repository subscription. Internal skills live in `shunk031/skills-private` and remain individually selected by the private dotfiles.
- When asked to add, change, or remove a skill, use the `shunk031-manage-public-private-skills` skill to decide which repository owns it before editing anything.
- Adding a public skill to `shunk031/skills` needs no subscription edit here. When a public skill is removed or renamed, add its old name to `SKILLS_RETIRED_NAMES` until the `skills` CLI supports non-interactive deletion. Third-party selections and the public repository subscription are configured in `install/common/skills.sh`; private selections stay in the private dotfiles.

## Comment Policy

- When adding or updating comments for shell scripts or shell-based executables, write them in English using shdoc-compatible format; use the `shunk031-shellscript-shdoc-docs` skill for detailed conventions.

## Development Setup

- In every new clone or worktree, run `make setup` before editing or committing.
- mise compatibility changes: When a tool or configuration change requires newer mise behavior, determine the minimum mise release that supports the change, raise `min_version` in the same pull request, and record the requirement in the pull request description.

## Test Policy

- Never run `bats` locally; use GitHub Actions only when the push/CI workflow is separately authorized.
