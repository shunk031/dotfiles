# ~/.agents

- This directory is applied as `~/.agents`.

## Linked paths

| Applied path                  | Canonical source                                                                                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `~/.agents/AGENTS.md`         | [dotfiles/home/private_dot_config/exact_agents/AGENTS.md](../private_dot_config/exact_agents/AGENTS.md)                                                                                                    |
| `~/.agents/AGENTS-private.md` | [dotfiles-private/home/private_dot_config/codex/private_AGENTS-private.md](https://github.com/shunk031/dotfiles-private/blob/main/home/private_dot_config/codex/private_AGENTS-private.md) |
| `~/.agents/agents`            | [dotfiles/home/private_dot_config/exact_agents/agents/](../private_dot_config/exact_agents/agents/)                                                                                                        |

## Skills

- `~/.agents/skills`, the shared skills pool, is not mapped from here.
  - It is a real directory the `skills` CLI installs into, reconciled against the allowlist in [install/common/skills.sh](../../install/common/skills.sh) on every apply.
  - It is listed in [chezmoiignore.d/common](../.chezmoitemplates/chezmoiignore.d/common) so chezmoi leaves it alone.

## Shared instructions

- `~/.agents/agents` supplies shared instructions to Codex and Claude wrapper agents.

## Editing

- The design keeps the home-facing path stable while the real files live in one git-friendly source tree.
- Edit the canonical source, not this adapter directory.
