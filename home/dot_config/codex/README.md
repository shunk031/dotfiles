This directory is the public canonical source for Codex guidance and custom-agent adapters.

- [AGENTS.md](AGENTS.md) is exposed as `~/.codex/AGENTS.md` through [home/dot_codex/symlink_AGENTS.md.tmpl](../../dot_codex/symlink_AGENTS.md.tmpl). It is a minimal Codex entrypoint that records the acknowledgment and points Codex to the shared guidance at `~/.agents/AGENTS.md`.
- [RTK.md](RTK.md) is exposed as `~/.codex/RTK.md` and referenced from `AGENTS.md`.
- [agents/](agents/) contains Codex TOML adapters exposed as `~/.codex/agents`. Long shared instructions remain under `~/.agents/agents`.
- Model providers, credentials, private profiles, and internal launchers are managed by the private dotfiles repository; do not add them here.
- [home/dot_codex/](../../dot_codex/) is only the adapter layer that exposes this source in the applied home layout.
