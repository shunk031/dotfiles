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

- Treat implementation requests as permission to edit repository files, run tests, and commit. They do not authorize pushing, pull requests, merges, `chezmoi apply`, runtime changes, deletion, or cleanup.
- Treat an explicit pull-request request as permission to push and create or update that pull request, but never as merge permission.
- Obtain explicit permission before merging, applying configuration, changing runtime state, deleting, or cleaning up files. Stop and ask when the permitted operation is unclear.

## Self-Improvement

- After a user correction or verified failure, fix the current task and identify a reusable prevention that addresses the root cause.
- Before changing persistent guidance, classify its scope and source of truth, search existing guidance for duplication, present the proposed change, and obtain approval.
- Persist only concise, actionable guidance that generalizes beyond the incident. Do not persist secrets, task-specific facts, transient state, incident narratives, or unverified assumptions.

## Work Safety

- Before modifying tracked files, inspect the branch and worktree. Treat the default branch as read-only and create a task-specific worktree even when it is clean.
- Create worktrees with `gwq add -b <task-branch>` and work in `$(gwq get <task-branch>)`. To use current `origin/main`, fetch first and run `git merge --ff-only origin/main` inside the new worktree; never pass the base ref as the second `gwq add` argument. Fall back to `git worktree add` only when `gwq` is unavailable.
- Read-only investigation may remain in the current checkout. Reuse a checkout for edits only when the user explicitly requests it or it is already a task-specific non-default worktree.
- Treat existing staged, unstaged, and untracked changes as user work. Before excluding or reverting a change, compare its before and after states and read its prose or code context; do not infer relevance from the filename or latest task alone. Never revert without proof and permission, and isolate task changes with another worktree or narrow staging.
- Preserve improvements even when they are small, including one-line writing changes that improve information order, citations, or naturalness. If task scope should exclude them, ask rather than reverting them.
- If an operation accidentally removes uncommitted work, report it immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output before any further overwrite.

## Working Style

- Keep reports and responses concise. Expand only when asked.
- Ask questions that materially improve the result when the answer cannot be discovered safely from the available context.
- Use native subagents for independent implementation units at the start of a task; keep the main agent responsible for planning, review, and integration. Keep model and launch configuration private or tool-specific.
- Do not overdesign error handling before implementing core behavior, and do not add error handling to final throwaway deliverables.
- Write tests before behavior-changing implementation, verify them, and then refactor.

## Specialized Workflows

- Use `manage-agent-guidance` when adding, moving, or deleting persistent instructions, agent wrappers, or skills.
- Use `structured-writing` for detailed instructions, plans, reports, documentation, and non-trivial bullet structure.
- Delegate GitHub issue, branch, commit, push, pull-request, and CI workflows to `gh-workflow-manager` by default. Provide repository/worktree context, task-relevant files, uncommitted-change handling, and completed validation; the main agent reviews the result and reports remaining blockers. Work directly only when the user explicitly requests it or the dedicated agent is unavailable.
