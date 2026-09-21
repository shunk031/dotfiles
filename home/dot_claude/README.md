# ~/.claude

- This directory is applied as `~/.claude`.

## Linked paths

### Public dotfiles

| Applied path                    | Canonical source                                                                                |
| ------------------------------- | ----------------------------------------------------------------------------------------------- |
| `~/.claude/CLAUDE.md`           | [dotfiles/home/dot_config/claude/CLAUDE.md](../dot_config/claude/CLAUDE.md)                     |
| `~/.claude/agents`              | [dotfiles/home/dot_config/claude/agents/](../dot_config/claude/agents/)                         |
| `~/.claude/commands`            | [dotfiles/home/dot_config/claude/commands/](../dot_config/claude/commands/)                     |
| `~/.claude/hooks/enforce-uv.sh` | [dotfiles/home/dot_config/claude/hooks/enforce-uv.sh](../dot_config/claude/hooks/enforce-uv.sh) |
| `~/.claude/rules`               | [dotfiles/home/dot_config/claude/rules/](../dot_config/claude/rules/)                           |
| `~/.claude/settings.json`       | [dotfiles/home/dot_config/claude/settings.json](../dot_config/claude/settings.json)             |

## Herdr hooks

Dotfiles owns the hook registration. The mise Herdr postinstall hook syncs the scripts bundled with the newly installed binary into `~/.claude/hooks/herdr-agent-state.sh` and `~/.codex/herdr-agent-state.sh`. These are the paths Herdr checks for integration status. Every public `chezmoi apply` also repairs missing or outdated scripts, including when the binary is already installed.

Apply the public dotfiles before the private Codex registration. The first public apply changes `~/.claude/hooks` from a source-directory symlink to a real directory, with a link for `enforce-uv.sh`. Until that migration is applied, the updater refuses to write through the old symlink. Later mise upgrades sync the assets without another apply.

The updater runs `herdr integration install` only against temporary configurations and copies the generated scripts. It never edits the real agent settings. Do not run the installer directly against these managed settings; its absolute-path command can add a duplicate registration.

When updating the Herdr pin, run `python3 -m unittest discover -s tests/python -p test_herdr_integration.py` with the new binary on `PATH`. It compares the upstream registration contract with the managed registration, checks integration status and repeated synchronization, and receives `startup` and `resume` session reports on an isolated socket. If the registration contract changes, update the source-owned settings in the public and private repositories together. The end-to-end CI jobs run this check with the installed binary.

## Skills

- `skills/` only carries a `.keep` marker.
  - Chezmoi creates `~/.claude/skills` as a real, Claude-only directory; this repository does not populate it.
  - The `skills` CLI links each installed skill into it when [run_after_30-reconcile-agent-skills.sh.tmpl](../.chezmoiscripts/common/run_after_30-reconcile-agent-skills.sh.tmpl) reconciles the shared pool at `~/.agents/skills`.
  - Skill installers can also write real skill directories there directly.

## Shared instructions

- Claude wrapper agents read shared instructions from `~/.agents/agents`.

## Editing

- The design keeps the home-facing path stable while the real files live in one git-friendly source tree.
- Edit the canonical source, not this adapter directory.
