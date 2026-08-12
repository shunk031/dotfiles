# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`

- Shared instructions: Read `~/.agents/AGENTS.md` first, then apply it together with this Codex-specific entrypoint.
- Commit attribution: When creating or amending a commit, end the commit message with `Co-authored-by: Codex <noreply@openai.com>` exactly once. Preserve existing trailers and keep one blank line before the trailer block.

## RTK

Use `rtk` for verbose shell commands when an equivalent filter exists.

Examples:

```bash
rtk git status
rtk git diff
rtk cargo test
rtk pytest -q
```

Use `rtk proxy <command>` when raw output is required. Check savings with `rtk gain`.
