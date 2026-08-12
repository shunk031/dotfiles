@~/.agents/AGENTS.md

> [!NOTE]
> After reading this `CLAUDE.md`, say: `🤖 I read ~/.claude/CLAUDE.md.`

## Claude Only

- There are currently no Claude-specific settings, but they may be added in the future.

## RTK

Use `rtk` for verbose shell commands when an equivalent filter exists. The Claude Code hook rewrites supported Bash commands automatically.

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

Use `rtk proxy <command>` when raw output is required. Check savings with `rtk gain`.
