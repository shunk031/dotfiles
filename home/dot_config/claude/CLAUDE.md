@~/.agents/AGENTS.md

> [!NOTE]
> After reading this `CLAUDE.md`, say: `🤖 I read ~/.claude/CLAUDE.md.`

## Claude only

### Orchestration

- When the main session uses a Fable-tier model, it must act only as a Herdr orchestrator. Before starting the task, read and follow the `shunk031-herdr-orchestrate-workers` skill.
- The main session must not edit files, implement changes, run tests, or perform any other task execution. It must delegate those actions to workers and limit its own role to planning, dispatch, coordination, state reconciliation, review, and acceptance decisions.

### Subagents

- Never run a subagent on a Fable-tier model. Pass an explicit `model` to every Agent call: `opus` by default, `haiku` or `sonnet` for mechanical searches. Omitting `model` makes the subagent inherit the session model, which silently burns Fable usage; Fable stays reserved for the main session.
