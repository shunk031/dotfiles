# ~/.claude

- This directory is applied as `~/.claude`.

## Linked paths

### Public dotfiles

| Applied path                    | Canonical source                                                                                |
| ------------------------------- | ----------------------------------------------------------------------------------------------- |
| `~/.claude/CLAUDE.md`           | [dotfiles/home/private_dot_config/claude/CLAUDE.md](../private_dot_config/claude/CLAUDE.md)                     |
| `~/.claude/agents`              | [dotfiles/home/private_dot_config/claude/agents/](../private_dot_config/claude/agents/)                         |
| `~/.claude/commands`            | [dotfiles/home/private_dot_config/claude/commands/](../private_dot_config/claude/commands/)                     |
| `~/.claude/hooks/enforce-uv.sh` | [dotfiles/home/private_dot_config/claude/hooks/enforce-uv.sh](../private_dot_config/claude/hooks/enforce-uv.sh) |
| `~/.claude/rules`               | [dotfiles/home/private_dot_config/claude/rules/](../private_dot_config/claude/rules/)                           |
| `~/.claude/settings.json`       | [dotfiles/home/dot_claude/modify_settings.json](modify_settings.json)                           |

`settings.json` is a regular file managed by a `modify_` template. It uses ChezMoi's JSON parser and recursive merge functions to preserve `model` and other unmanaged object keys; conflicting managed values win. Empty input creates the full initial settings file, and invalid JSON fails before chezmoi changes the target.

The old source JSON stays in place as an ignored migration referent for existing symlinks. The existing ignore rule excludes its `.config/claude` destination, so it is not a second managed target. Chezmoi reads the live symlink's referent before replacing it with a regular file. Review `chezmoi diff` and get the machine user's approval before the first apply; this change does not migrate any machine.

## Herdr hooks

- Public `chezmoi apply` runs `mise install`, repairs outdated or missing Herdr integrations, and restores the agent settings changed by the installer.
- Dotfiles manages hook registration. Do not run `herdr integration install` against the managed settings, as it can add duplicate hooks.

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
