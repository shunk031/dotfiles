# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`

- Shared instructions: Read `~/.agents/AGENTS.md` first, then apply it together with this Codex-specific entrypoint.

## Codex only

- Explicit actors: Codex must state who makes each decision and who performs each action when an explanation or plan would otherwise leave responsibility ambiguous.
- Interrupted work: When new user input arrives during unfinished work, Codex must decide whether it replaces or extends the active request. Unless it clearly replaces the request, keep the original objective and unresolved acceptance criteria in the active plan, resume them after handling the interruption, and do not report completion until both are complete.
- Commit attribution: When creating or amending a commit, end the commit message with `Co-authored-by: Codex <noreply@openai.com>` exactly once. Preserve existing trailers and keep one blank line before the trailer block.
