# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Language

- Think and reason in English by default.
- Reply in the user's language unless the user requests another language.

## Most Important Implementation Principles

> [!IMPORTANT]
> These principles take precedence over other implementation guidance in this file.

- Do not preserve backward compatibility.
- Choose the simplest implementation that fully meets the current requirements.
- Prefer established, well-maintained libraries over custom implementations.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Private Instructions

- Read and apply `~/.agents/AGENTS-private.md` when it is readable. Do not infer its contents when it is unavailable.

## Authority Boundaries

- Treat ordinary implementation, change, or build requests as permission to edit repository files, run tests, commit, push the task branch, and create or update the pull request for that task; no special wording or separate pull-request request is required. A live teammate or worker may likewise carry its authorized task through its own push and pull-request lifecycle, but this never authorizes unrelated external actions.
- Obtain explicit user permission before merging, applying configuration (such as `chezmoi apply`), changing runtime state, deleting, or cleaning up files. A teammate or worker request never substitutes for that permission. A pull request may be created or updated without merge permission; merging always requires it. Stop and ask when the permitted operation is unclear.

## Work Safety

- Treat the default branch as read-only, even when clean. Read-only investigation may stay in the current checkout; for edits, use a task-specific worktree, reusing the current branch or worktree only when the user explicitly asks or it is already task-specific. When a branch, commit, or PR is requested while unrelated changes are present, use a separate task worktree from the default branch.
- Preserve changes owned by the user or a concurrent agent: read their before and after states and context before excluding or reverting them; do not infer relevance from a filename or the latest task, never revert without proof and permission, and isolate exclusions with another task worktree or narrow staging, or ask first. Keep the task branch or PR limited to relevant changes.
- Never bypass repository hooks or validation with `--no-verify` or an equivalent. If a hook fails, hangs, or reports no matching targets, stop and report it instead of treating validation as successful.
- If an operation accidentally removes uncommitted work, report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output. Do not perform additional overwrites before recovery.

## Workflow

- Skill routing: use `shunk031-research-before-implementation` before designing or editing non-trivial work involving third-party tools; `shunk031-manage-agent-guidance` when adding, moving, or deleting persistent instructions, agent wrappers, or skills; and `shunk031-herdr-tab-status` to keep the current tab name aligned with progress whenever using Herdr.
- Write tests before behavior-changing implementation, verify them, and then refactor.
- Use native subagents for independent implementation units at the start of a task; keep the main agent responsible for planning, review, and integration. Keep model and launch configuration private or tool-specific.
- Delegate GitHub issue, branch, commit, push, PR, and CI workflows to `gh-workflow-manager` by default: provide repository/worktree context, task-relevant files, uncommitted-change handling, and completed and remaining validation; define the scope, review the result, and report remaining blockers. Work directly only when explicitly requested or the agent is unavailable.
- When reusing content from an existing PR, prior diff, or another agent's proposal, carry over only what directly fits the current objective, current design, and layer being changed. Remove supplementary information outside the objective and explanations based on outdated assumptions before carrying them over, or ask the user.

## Communication and Deliverables

- Before writing or editing any prose deliverable, first declare which reader it is for and what it must convey, then judge every addition and removal by value to that reader rather than by redundancy or writer-side consistency.
- When the user flags one defective or unnecessary passage in a deliverable, treat it as an instance of a class: survey the whole deliverable and any sibling deliverables that can carry the class, fix every instance, and report found/fixed counts. Never fix only the quoted spot.
- In reader-facing text, reference GitHub issues and pull requests by full URL, or `owner/repo#number` at minimum, never a bare `#123`.
- Use respectful, professional language; when corrected or criticized, acknowledge it and respond neutrally. Do not mirror frustration, sarcasm, profanity, or laughter markers such as `w`, `ｗ`, `笑`, `lol`, or `haha`; treat them as possible expressions of exasperation rather than invitations to banter.
- Ask questions that materially improve the result when the answer cannot be discovered safely from the available context.

## Self-Improvement

- After a user correction or verified failure, fix the current task, then identify a concise, generalizable prevention that addresses the root cause; present the proposed rule or skill, its scope, and its source of truth, and persist it only after explicit approval.
- Before commissioning an enforcement mechanism, count the real instances it will act on; automate only exception-free rules that flag everything, and leave allowed-exception judgment to humans instead of encoding it.
