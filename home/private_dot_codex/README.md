# ~/.codex

- This directory is applied as `~/.codex`.

## Linked paths

### Public dotfiles

| Applied path         | Canonical source                                                                          |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `~/.codex/AGENTS.md` | [dotfiles/home/private_dot_config/codex/AGENTS.md](../private_dot_config/codex/AGENTS.md) |
| `~/.codex/agents`    | [dotfiles/home/private_dot_config/codex/agents/](../private_dot_config/codex/agents/)     |

### Private dotfiles

| Applied path           | Canonical source                                                                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `~/.codex/config.toml` | [dotfiles-private/home/private_dot_codex/modify_private_config.toml](https://github.com/shunk031/dotfiles-private/blob/main/home/private_dot_codex/modify_private_config.toml) |
| `~/.codex/hooks.json`  | [dotfiles-private/home/private_dot_codex/private_hooks.json](https://github.com/shunk031/dotfiles-private/blob/main/home/private_dot_codex/private_hooks.json)                 |
| `~/.codex/hooks`       | [dotfiles-private/home/private_dot_codex/private_hooks/](https://github.com/shunk031/dotfiles-private/tree/main/home/private_dot_codex/private_hooks)                          |

## Skills

- `~/.agents/skills` is shared rather than mapped from this adapter; see [the shared skill pool](../exact_dot_agents/README.md#shared-skill-pool).

## Shared instructions

- Codex custom-agent adapters read shared instructions from `~/.agents/agents`.

## Editing

- Edit the canonical source, not this adapter directory.
