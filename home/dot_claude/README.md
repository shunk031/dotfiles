# ~/.claude

- This directory is applied as `~/.claude`.

## Linked paths

### Public dotfiles

| Applied path | Canonical source |
| --- | --- |
| `~/.claude/CLAUDE.md` | [dotfiles/home/dot_config/claude/CLAUDE.md](../dot_config/claude/CLAUDE.md) |
| `~/.claude/agents` | [dotfiles/home/dot_config/claude/agents/](../dot_config/claude/agents/) |
| `~/.claude/commands` | [dotfiles/home/dot_config/claude/commands/](../dot_config/claude/commands/) |
| `~/.claude/hooks` | [dotfiles/home/dot_config/claude/hooks/](../dot_config/claude/hooks/) |
| `~/.claude/rules` | [dotfiles/home/dot_config/claude/rules/](../dot_config/claude/rules/) |
| `~/.claude/settings.json` | [dotfiles/home/dot_config/claude/settings.json](../dot_config/claude/settings.json) |

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
