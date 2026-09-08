@~/.agents/AGENTS.md

> [!NOTE]
> After reading this `CLAUDE.md`, say: `🤖 I read ~/.claude/CLAUDE.md.`

## Claude Only

- Never run a subagent on a Fable-tier model. Pass an explicit `model` to every Agent call: `opus` by default, `haiku` or `sonnet` for mechanical searches. Omitting `model` makes the subagent inherit the session model, which silently burns Fable usage; Fable stays reserved for the main session.
