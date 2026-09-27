# AGENTS.md

> [!NOTE]
>
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Language

- Think and reason in English by default.
- Reply in the user's language unless the user requests another language.

## Most Important Implementation Principles

> [!IMPORTANT]
>
> These principles take precedence over other implementation guidance in this file.

- Do not preserve backward compatibility.
- Choose the simplest implementation that fully meets the current requirements.
- Prefer established, well-maintained libraries over custom implementations.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Private Instructions

- Read and apply `~/.agents/AGENTS-private.md` when it is readable. Do not infer its contents when it is unavailable.

## Authority Boundaries

- Treat ordinary implementation, change, or build requests as permission to edit repository files, run tests, commit, push the task branch, and create or update the pull request for that task; no special wording or separate pull-request request is required. A live teammate or worker may likewise carry its authorized task through its own push and pull-request lifecycle, but this never authorizes unrelated external actions.
- Merging, applying configuration (such as `chezmoi apply`), changing runtime state, deleting, and cleaning up files require explicit user permission for that operation and scope. Carry existing permission forward without asking again, but do not extend it to another target or a materially changed result. A worker cannot grant user-only permission. Finish authorized preparation that does not depend on a missing decision.
- When a design depends on a choice about user-owned rulesets, branch protection, secrets, or repository or service settings, present the options and wait for the user's choice before editing the dependent implementation. Independent investigation may continue. Do not treat those settings as fixed constraints to design around.

## Work Safety

- Treat the default branch as read-only, even when clean. Read-only investigation may stay in the current checkout; for edits, use a task-specific worktree, reusing the current branch or worktree only when the user explicitly asks or it is already task-specific. When a branch, commit, or PR is requested while unrelated changes are present, use a separate task worktree from the default branch.
- Preserve changes owned by the user or a concurrent agent: read their before and after states and context before excluding or reverting them; do not infer relevance from a filename or the latest task, never revert without proof and permission, and isolate exclusions with another task worktree or narrow staging, or ask first. Keep the task branch or PR limited to relevant changes. Formatting that the user's configured hooks or formatters apply to files you edit, such as Markdown table realignment, is intended output rather than unrelated churn: keep it, never revert it, and never flag it in a review.
- Never bypass repository hooks or validation with `--no-verify` or an equivalent. If a hook fails, hangs, or reports no matching targets, stop and report it instead of treating validation as successful.
- If an operation accidentally removes uncommitted work, report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output. Do not perform additional overwrites before recovery.

## Workflow

- Use the `shunk031-research-before-implementation` skill when the user requests research or a design or experiment depends on unverified third-party behavior. A spelling correction or local refactor with established behavior does not require a fresh external investigation. Reuse verified sources until a new assumption or changed version needs checking.
- Use the `shunk031-manage-agent-guidance` skill for persistent instruction changes and the `shunk031-herdr-tab-status` skill when using Herdr. Load other skills and their references for the current task, not merely because a related keyword appears.
- Design toward the end state the request implies instead of appending to the current state. Before adding anything, verify what each existing element does and whether it still earns its place; removing or reshaping is a normal outcome, not an escalation.
- For behavior changes, first identify the regression or acceptance check, then implement and verify the change. Use existing tests when they cover it; add a focused test for an uncovered behavior. Run required repository checks, and broaden testing when the change or a failure warrants it.
- Run `date` and print its output in every report on work in progress, alongside how long that work has been running. Never write a time you did not just read.
- Use native subagents when independent work benefits from delegation; handle small, tightly coupled changes directly. The main agent owns planning, review, and integration. Keep model and launch configuration private or tool-specific.
- Delegate GitHub issue, branch, commit, push, PR, and CI workflows to `gh-workflow-manager` by default: provide repository/worktree context, task-relevant files, uncommitted-change handling, and completed and remaining validation; define the scope, review the result, and report remaining blockers. Work directly only when explicitly requested or the agent is unavailable.
- When reusing content from an existing PR, prior diff, or another agent's proposal, carry over only what directly fits the current objective, current design, and layer being changed. Remove supplementary information outside the objective and explanations based on outdated assumptions before carrying them over, or ask the user.
- Keep the requested outcome and unresolved acceptance criteria in view until the authorized work is complete, including applicable validation and PR checks. A status question or correction does not cancel unfinished work. Report any remaining external decision or unavailable check instead of claiming completion from the first implementation alone.

## Communication and Deliverables

- Write prose for its intended reader and purpose. Explain the audience when it affects a decision; judge additions and removals by their value to that reader.
- When the user flags a defect, check the same defect class across the deliverable and relevant siblings. Fix all in-scope instances, preserve meaningful exceptions, and report the scope and results. Use counts when they help the reader verify a sweep.
- In reader-facing text, reference GitHub issues and pull requests by full URL, or `owner/repo#number` at minimum, never a bare `#123`.
- Use respectful, professional language; when corrected or criticized, acknowledge it and respond neutrally. In critical messages, `w` and `ｗ` should be interpreted as signs of severe disappointment, disbelief, or exasperation—not amusement. Never mirror them. Treat their presence as a signal to become more serious, restrained, and precise.
- Ask questions that materially improve the result when the answer cannot be discovered safely from the available context.

## Self-Improvement

- After a user correction or verified failure, fix the task and identify the root cause. Prefer a correction in the existing implementation or guidance owner over another universal rule. A request to improve that guidance authorizes the scoped revision; otherwise propose durable changes with their scope and owner, and wait for approval before persisting them.
- Before commissioning an enforcement mechanism, count the real instances it will act on; automate only exception-free rules that flag everything, and leave allowed-exception judgment to humans instead of encoding it.
