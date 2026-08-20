---
name: shunk031-codex-worker-prompting
description: Write task prompts, follow-ups, and authorizations for Codex-family worker models. Use whenever an orchestrator dispatches work to Codex workers in Herdr or another harness.
---

# Codex Worker Prompting

Write prompts that make worker decisions and stop conditions explicit.

## Eight principles

1. **Write contracts, not vibes.** Put machine-checkable conditions in every instruction: exact SHAs, exact commands, exact pass/fail gates, and explicit STOP conditions. Have workers self-check against these gates, and treat pushback that a gate is impossible as signal, not defiance. Pair every gate with a statement of what it does not measure, and treat a gate conflict like an impossible gate: stop and report instead of silently satisfying one gate.
2. **Assume literal execution.** Expect every assertion to be executed as written, including mistakes. Add verification clauses such as read-backs, `ls-remote` comparisons, and precondition checks so workers halt on stale or wrong facts. State invariants explicitly, including numbers, claim strength, attribution, file scope, and section order; a literal executor treats every unstated property as mutable.
3. **Bound the loops, not the task count.** Let a dispatch carry a full lifecycle, but give every retryable step an explicit retry budget, wait duration, and terminal report state. For judgment tasks such as screening or review, state the decision rule, uncertain-case default, and cost asymmetry justifying that default. Encode authorization boundaries, including user-owned merges and destructive actions, as STOP conditions inside the prompt.
4. **Enumerate VERIFIED environment facts inline.** List proxies, push-URL pitfalls, API field IDs, sandbox variables, and auth fallbacks using only verified facts. Write unverified beliefs as hypotheses to verify, and supply the exact command block to run instead of describing it.
5. **Dispatch requirements and acceptance criteria, not implementations.** If you believe a tool or approach is unsuitable, state that belief as a hypothesis for worker verification and require research before implementation for tool choices. Workers execute solution framing literally and will build exactly the wrong thing well.
6. **Write the dispatch in the artifact's target register.** A worker mirrors dispatch vocabulary and constraints into deliverables. For reader-facing artifacts, keep internal codenames and audit constraints out of the prompt body, and state that compliance evidence belongs in the PR body, not the document.
7. **Fix the class, prove the sweep.** When a reviewer names defect instances, instruct the worker to remove the defect class. Require sweep evidence: an enumerate-and-classify table of every candidate, or a detector that reproduces the known-bad state before the fix and reports zero after it.
8. **Rotate on role and degradation, then on context.** Start a fresh session for every independent review verdict, retire sessions showing degraded output or anchoring to a failed approach, and rotate long-lived workers at natural boundaries before context runs out; a fixed remaining-context percentage is not a reliable trigger. When re-dispatching after a crash or rotation, enumerate on-disk state, including paths and whether each artifact is final, and state what must not be recomputed. Externalize handoff state in handoff documents and PR comments where repository policy allows; keep PR bodies reader-facing rather than a state ledger.

Transport mechanics such as dispatch delivery, report formats, and reconciliation belong to the `shunk031-orchestrate-herdr-workers` skill. This skill owns only prompt-writing guidance.
