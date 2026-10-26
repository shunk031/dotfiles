This directory is the public canonical source for Codex guidance and custom-agent adapters.

- [AGENTS.md](AGENTS.md) is rendered at `~/.codex/AGENTS.md` by [AGENTS.md.tmpl](../../private_dot_codex/AGENTS.md.tmpl). It is a minimal Codex entrypoint that records the acknowledgment and points Codex to the shared guidance at `~/.agents/AGENTS.md`.
- [agents/](agents/) contains Codex TOML adapters rendered under `~/.codex/agents`. Long shared instructions remain under `~/.agents/agents`.
- Model providers, credentials, private profiles, and internal launchers are managed by the private dotfiles repository; do not add them here.
- [home/private_dot_codex/](../../private_dot_codex/) contains templates that render this source in the applied home layout.
