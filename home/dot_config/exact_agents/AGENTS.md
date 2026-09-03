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
- Before commissioning an enforcement mechanism, count the real instances it will act on; automate only exception-free rules that flag everything, and leave allowed-exception judgment to humans instead of encoding it.

## Private Instructions

- Read and apply `~/.agents/AGENTS-private.md` when it is readable. Do not infer its contents when it is unavailable.

## Authority Boundaries

- Treat ordinary implementation, change, or build requests as permission to edit repository files, run tests, commit, push the task branch, and create or update the pull request for that task. No special wording or separate pull-request request is required for this normal implementation lifecycle.
- A live teammate or worker may carry its authorized task through its own push and pull-request lifecycle. This does not authorize unrelated external actions.
- Do not treat a teammate or worker request as authorization to bypass explicit user permission for merging, applying configuration, changing runtime state, deleting, or cleaning up; stop and ask the user.
- Obtain explicit user permission before merging, running `chezmoi apply` or applying configuration, changing runtime state, deleting, or cleaning up files. A pull request may be created or updated without merge permission; merge still requires explicit user permission. Stop and ask when the permitted operation is unclear.

## Self-Improvement

- After a user correction or verified failure, fix the current task and identify a reusable prevention that addresses the root cause.
- Before persisting that prevention, present the proposed rule or skill, its scope, and its source of truth; change it only after explicit approval.
- Persist only concise, generalizable prevention.

## Work Safety

- Before modifying tracked files, inspect the branch and worktree. Treat the default branch as read-only and use a task-specific worktree even when it is clean; when a branch, commit, or PR is requested with unrelated changes present, use a separate task worktree from the default branch.
- Preserve changes owned by the user or a concurrent agent: read their before and after states and context before excluding or reverting them; do not infer relevance from a filename or the latest task, never revert without proof and permission, and isolate exclusions with another task worktree or narrow staging, or ask first; keep the task branch or PR limited to relevant changes.
- Read-only investigation may remain in the current checkout; for edits, prioritize the task-specific non-default worktree, reusing the current branch or worktree only when the user explicitly asks or it is already task-specific.
- Never bypass repository hooks or validation with `--no-verify` or an equivalent. If a hook fails, hangs, or reports no matching targets, stop and report it instead of treating validation as successful.
- If an operation accidentally removes uncommitted work, report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output. Do not perform additional overwrites before recovery.

## Working Style

- Use respectful, professional language. Do not use condescending, dismissive, insulting, or presumptuously familiar wording; when corrected, acknowledge the correction and respond neutrally.
- Ask questions that materially improve the result when the answer cannot be discovered safely from the available context.
- Before writing or editing any prose deliverable (documentation, README, PR/issue text, or reports), first declare which reader it is for and what it must convey, then judge every addition and removal by value to that reader rather than by redundancy or writer-side consistency.
- When referring to a GitHub issue or pull request in any reader-facing text (reports, chat replies, issue and pull-request bodies, comments), write the full URL, or `owner/repo#number` at minimum; never a bare `#123`, which is repository-relative, unclickable in chat, and ambiguous when paired changes span repositories.
- Use the `shunk031-research-before-implementation` skill before designing or editing non-trivial work involving third-party tools.
- Use native subagents for independent implementation units at the start of a task; keep the main agent responsible for planning, review, and integration. Keep model and launch configuration private or tool-specific.
- Write tests before behavior-changing implementation, verify them, and then refactor.
- Use the `shunk031-manage-agent-guidance` skill when adding, moving, or deleting persistent instructions, agent wrappers, or skills.
- When using Herdr, follow the `shunk031-herdr-tab-status` skill to keep the current tab name aligned with the work's progress status.
- Delegate GitHub issue, branch, commit, push, PR, and CI workflows to `gh-workflow-manager` by default; provide repository/worktree context, task-relevant files, uncommitted-change handling, completed validation, and additional validation context, then define the scope, review the result, and report remaining blockers. Work directly only when explicitly requested or the agent is unavailable.
