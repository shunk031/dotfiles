# ~/.claude

- This directory is applied as `~/.claude`.

## Managed paths

### Public dotfiles

| Applied path              | Rendered from canonical source                                                                 |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| `~/.claude/CLAUDE.md`     | [claude/CLAUDE.md](../private_dot_config/claude/CLAUDE.md) by [CLAUDE.md.tmpl](CLAUDE.md.tmpl) |
| `~/.claude/agents`        | [claude/agents/](../private_dot_config/claude/agents/) by [agents/](agents/)                   |
| `~/.claude/commands`      | [claude/commands/](../private_dot_config/claude/commands/) by [commands/](commands/)           |
| `~/.claude/rules`         | [claude/rules/](../private_dot_config/claude/rules/) by [rules/](rules/)                       |
| `~/.claude/settings.json` | [modify_settings.json](modify_settings.json)                                                   |

`settings.json` is a regular file managed by a `modify_` template. It uses ChezMoi's JSON parser and recursive merge functions to preserve unmanaged object keys; managed values such as `model` override existing values. Empty input creates the full initial settings file, and invalid JSON fails before chezmoi changes the target.

Set `[data]` and `claude.model = "claude-opus-5-5"` in `~/.config/chezmoi/chezmoi.toml` to override the per-machine model; omit the key to keep the `fable` default.

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

- The templates keep the home-facing paths stable while canonical files live in one git-friendly source tree.
- Edit the canonical source, not this adapter directory.
