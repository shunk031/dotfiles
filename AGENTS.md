# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read the project-level AGENTS.md for shunk031/dotfiles.`

## Repository Context

- Tooling: This repository is managed with [`chezmoi`](https://www.chezmoi.io/) ([GitHub](https://github.com/twpayne/chezmoi)).
- Public source: Files under `home/` are the public source state and are applied by `chezmoi` into the user's `$HOME` directory.
- Private source: Private dotfiles are managed separately from `~/.local/share/chezmoi-private` with config at `~/.config/chezmoi-private/chezmoi.yaml`.
- Management boundary: Treat the public `home/` tree and the private `chezmoi` source/config as separate management domains.
- Codex boundary: This repo manages the Codex CLI, shared guidance, `~/.codex/AGENTS.md`, and `~/.codex/agents`; `dotfiles-private` manages `~/.codex/config.toml`, private profiles, credentials, and internal launchers.

## Comment Policy

- When adding or updating comments for shell scripts or shell-based executables, write them in English using shdoc-compatible format; use `shunk031-shdoc-shell-docs` for detailed conventions.

## Development Setup

- In every new clone or worktree, run `make setup` before editing or committing.

## mise Bootstrap Compatibility

- Compatibility floor: Treat the top-level `min_version` in `home/dot_mise/config.toml` as the lowest mise version supported by the repository, not as the desired installed version. New machines install this exact version, while existing newer installations must not be downgraded.
- Renovate ownership: Let Renovate manage versions under `[tools]`, but do not configure Renovate to raise `min_version` merely because a new mise release exists.
- Atomic updates: Raise `min_version` only in the same pull request as a tool or configuration change that requires newer mise behavior. Record the requirement in the pull request description.
- Failure handling: When a Renovate tool update fails with the compatibility-floor version, determine the minimum mise release that supports the update and change `min_version` in that Renovate pull request.
- Fresh-install validation: Changes to `home/dot_mise/config.toml`, `install/common/mise.sh`, or the mise `run_once` and `run_after` scripts must run both Ubuntu and macOS setup workflows. These workflows must install the configured `min_version` on a clean runner and complete `mise install`.
- Avoiding workarounds: Do not replace the compatibility floor with periodic bumps, an unpinned `latest` bootstrap, or automerge whose only purpose is hiding recurring mise update pull requests.

## Test Policy

- Never run `bats` locally; use GitHub Actions only when the push/CI workflow is separately authorized.
