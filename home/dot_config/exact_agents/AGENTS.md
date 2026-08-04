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
- Obtain explicit permission before merging, applying configuration, changing runtime state, deleting, or cleaning up files.

## Work Safety

- Treat a default-branch checkout as read-only for tracked files. Before editing, create a task-specific worktree with `gwq add -b <task-branch>` and work in `$(gwq get <task-branch>)`.
- To start from current `origin/main`, fetch first, create the worktree without passing a base ref as the second `gwq add` argument, then run `git merge --ff-only origin/main` inside it.
- Treat existing staged, unstaged, and untracked changes as user work. Do not revert them; isolate task changes in another worktree or with narrow staging.

## Working Style

- Ask questions that materially improve the result when the answer cannot be discovered safely.
- Use native subagents for independent implementation work when available; keep environment-specific models and launch methods in private or tool-specific configuration.
- Write tests before behavior-changing implementation and verify them before refactoring.
- Make implementation plans concrete enough to identify affected paths, interfaces, behavior, tests, and assumptions.
