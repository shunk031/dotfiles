# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`

- Shared instructions: Read `~/.agents/AGENTS.md` first, then apply it together with this Codex-specific entrypoint.
- Commit attribution: When creating or amending a commit, end the commit message with `Co-authored-by: Codex <noreply@openai.com>` exactly once. Preserve existing trailers and keep one blank line before the trailer block.

## RTK

- Prefix supported shell commands with `rtk` to reduce command output, for example `rtk git status`, `rtk cargo test`, or `rtk pytest -q`.
- Use `rtk gain` to inspect savings and `rtk proxy <command>` when raw output is required.
