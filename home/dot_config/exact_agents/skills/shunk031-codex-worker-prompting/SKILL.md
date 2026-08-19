---
name: shunk031-codex-worker-prompting
description: Write task prompts, follow-ups, and authorizations for Codex-family worker models. Use whenever an orchestrator dispatches work to Codex workers in Herdr or another harness.
---

# Codex Worker Prompting

Write prompts that make worker decisions and stop conditions explicit.

## Five principles

1. **Write contracts, not vibes.** Put machine-checkable conditions in every instruction: exact SHAs, exact commands, exact pass/fail gates, and explicit STOP conditions. Have workers self-check against these gates, and treat pushback that a gate is impossible as signal, not defiance.
2. **Assume literal execution.** Expect every assertion to be executed as written, including mistakes. Add verification clauses such as read-backs, `ls-remote` comparisons, and precondition checks so workers halt on stale or wrong facts.
3. **Bound each dispatch.** Give one bounded task per dispatch and name explicit stop-and-report points. Encode authorization boundaries, including user-owned merges and destructive actions, as STOP conditions inside the prompt.
4. **Enumerate environment facts inline.** State proxies, push-URL pitfalls, API field IDs, sandbox variables, and auth fallbacks in the prompt. Workers do not discover unstated environment facts reliably and may burn time or fail without them.
5. **Rotate before context depletion.** Rotate workers below roughly 30 percent remaining context at natural task boundaries. Externalize state in PR bodies, receipts, and handoff documents so successors resume at full precision.

Transport mechanics such as dispatch receipts, report formats, and reconciliation belong to the `shunk031-orchestrate-herdr-workers` skill. This skill owns only prompt-writing guidance.
