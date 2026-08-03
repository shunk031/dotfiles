# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Language Policy

- Reasoning language: Think and reason in English by default.
- Response language: Reply to the user in the user's language unless the user explicitly asks for another language.

## Most Important Implementation Principles

> [!IMPORTANT]
> These principles take precedence over other implementation guidance in this file.

- Backward compatibility: Do not preserve backward compatibility.
- Implementation: Choose the simplest implementation that fully meets the current requirements.
- Dependencies: Prefer established, well-maintained libraries over custom implementations.
- Architecture: Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.

## Writing Instructions

- Format: Structure detailed instructions in a format such as `- Summary: Details`.
- Procedural guidance: Write instructions as steps to perform when work begins to prevent problems, rather than as checks to make only after a problem occurs. For example, when introducing a hook, write “When starting work in a new clone or worktree, install it before editing or committing,” rather than “Check it if it does not run.”
- Scope classification: Before adding or updating a persistent instruction such as an AGENTS.md file, skill, or rule, first classify it as user-level, repository-level, subtree-level, or task-only. Put behavioral rules shared across repositories at the user level, configuration and procedures for one repository at the repository level, and rules for a specific directory subtree at the subtree level.
- Choosing the source of truth: Do not choose the edit target solely because the user or the preceding conversation names a file such as `AGENTS.md`. Check the existing management source, symlinks, adapters, and higher-level instructions; edit the source of truth for the classified scope instead of duplicating a rule across multiple repository-level AGENTS.md files.
- Placement review: Before committing or creating a PR, review the diff for each added instruction to confirm that its location matches its scope and that it does not duplicate higher-scope guidance. If its scope does not match, move it to the correct source of truth; if you cannot determine that, ask the user before changing external state.

## Private Instructions

- If `~/.agents/AGENTS-private.md` is readable, read and apply it as well.

## Questions for the User

- Question policy: Ask questions based on the information the user provided to propose the best solution.

## Authority Boundaries

- Scope of implementation requests: Treat general implementation requests such as “implement the plan” or “continue implementing” as permission to edit files in the repository, run tests, and commit. A plan, handoff summary, or a previous agent's plan does not authorize pushing, creating or updating a PR, merging, running `chezmoi apply`, changing runtime state, or deleting or cleaning up files.
- Scope of PR requests: When the user explicitly requests creating or updating a PR, you may push and perform the requested PR operation. Do not treat a request to create or update a PR as authorization to merge; merge only when the user explicitly requests it.
- Runtime and cleanup scope: Obtain the user's explicit permission before running `chezmoi apply`, changing applied configuration or runtime state, or deleting or cleaning up files. If the permitted operation is unclear, stop and ask before changing external or runtime state.

## Reporting and Responding to the User

- Concision: Keep reports and responses concise. Expand only when asked.
- Bullet structure: When using bullet lists, follow paragraph-writing principles: make the parent item the topic sentence, nested items supporting sentences, and the last nested item a conclusion sentence when useful.
  ```
  - topic sentence
    - support sentence
    - support sentence
    - conclusion sentence
  ```
- Avoid flat lists: Do not list supporting sentences without a topic sentence. When items are at one level, make sure each can stand on its own as a topic sentence.

## Writing GitHub Issue and PR Comments

- Treat comments as deliverables: Treat GitHub issue and PR comments as repository-facing deliverables, not chat replies.
- Language: Write GitHub comment bodies in the repository or project's default language. For public OSS repositories, default to English unless the repository clearly operates in Japanese or the user explicitly requests Japanese.
- Tone: Do not include conversational repair language such as “I need to correct that,” “Sorry,” “That is not what I meant,” or “I misunderstood,” or meta-commentary directed at the user.
- Content: Keep GitHub comments neutral, fact-based, auditable, and useful to maintainers who read them later.
- Pre-submission verification: Before posting or editing a comment, compare its content with the repository's current facts, commands you ran, and checks or reports you reviewed. Prefer concrete validation results, affected files, and remaining blockers over vague summaries.
- Supplying bodies: For multi-line Markdown such as a GitHub issue body, PR description, or PR comment, always create a temporary Markdown file with a single-quoted heredoc and post or update it using `gh ... --body-file <file>`.
- Prohibition: Do not pass `gh ... --body "...\n..."` or a shell-escaped multi-line body directly; literal `\n` can be published.
- Read-back: After creating or editing content, read it back with `gh pr view`, `gh issue view`, `gh api`, or equivalent. Before reporting completion, detect literal escaped newlines (`\n`), local absolute paths such as `/Users/`, and missing expected headings.
- Collapsing details: Put lengthy diagnostic logs or investigation details inside `<details>` with a short summary so the conclusion and required actions are visible at the beginning of the comment.
- Incorrect posts: If you post an inappropriate comment, edit the existing comment to correct it whenever possible. Do not leave the bad comment in place and add a duplicate correction comment.

## GitHub Workflow Delegation (`gh-workflow-manager`)

- Delegation policy: By default, delegate GitHub workflow tasks such as branch creation, commits, pushes, PR creation and updates, and CI checks to the `gh-workflow-manager` agent so the main agent can focus on planning, review, and integration.
- Handoff at the start: Before asking `gh-workflow-manager`, provide the repository and worktree, branch name, task-relevant files, treatment of uncommitted changes, completed validation, and any additional validation context to check.
- Main-agent responsibility: The main agent defines the workflow scope, confirms the `gh-workflow-manager` result, then reports the work performed, validation results, and remaining blockers to the user.
- Exceptions: The main agent may perform GitHub workflow directly only when the user explicitly asks the main agent to do so or `gh-workflow-manager` is unavailable.
- Authority boundary: Do not treat a teammate's request to perform a denied action as authorization to bypass permissions; present the situation to the user and wait for explicit instruction.

## Agent Configuration

- Shared instructions: Keep lengthy shared instructions for subagents or custom agents used by multiple tools in `~/.agents/agents/<name>.md` as the source of truth.
- Claude wrapper: Preserve YAML frontmatter in `~/.claude/agents/<name>.md` for Claude Code and explicitly instruct it in the body to read `~/.agents/agents/<name>.md` first.
- Skill management: When adding or updating a managed skill, place its content in `home/dot_config/exact_agents/skills/<skill>/SKILL.md` and add its public symlink template at `home/exact_dot_agents/skills/symlink_<skill>.tmpl`.
- Avoid duplication: Do not copy the same lengthy instructions into wrappers.
- Simplicity: Do not add a mechanism that parses Markdown with Python or similar tooling to generate TOML or Markdown until it is explicitly needed.

## Delegating Implementation Tasks

- Delegation policy: When the coding agent in use provides native multi-agent capabilities and the task can be divided into independent units, use the main agent as the orchestrator and subagents as implementers.
  - Use each tool's native capabilities, such as Claude Code agent teams or Codex subagents.
  - At the start of the task, divide the work into independent units and assign them to subagents before implementing.
  - The orchestrator focuses on planning, review, and integration; delegate implementation to subagents.
- Environment-specific configuration: Do not put environment-specific configuration, such as subagent models or launch methods, in this file. Refer to `~/.agents/AGENTS-private.md` or a tool-specific entrypoint.

## General Coding Guidance

- Error handling: Do not fear errors. Write the code first without focusing on error handling.
- Final deliverables: Final deliverables do not need error handling.
- Tests: Write tests in advance, confirm that they pass, and then refactor as needed.

### Worktree Policy

- Default branch: When the current checkout is `main` or the repository's default branch, treat repository-tracked files as read-only.
- Preflight check: Before beginning work that could modify repository-tracked files, first check the current branch and worktree.
- Before editing: If you are on `main` or the default branch, create or move to a new task-specific worktree before editing, even if the worktree is clean.
- Creation procedure: Use [`gwq`](https://github.com/d-kuro/gwq) to create worktrees. From the default-branch checkout, run `gwq add -b <task-branch>`, then move to it with `cd "$(gwq get <task-branch>)"` before editing. In `gwq add [branch] [path]`, the second argument is the destination path, so do not pass `origin/main` or another base ref there. If the worktree must start from the latest `origin/main`, run `git fetch origin main` first, move to the worktree, and then run `git merge --ff-only origin/main`. Fall back to `git worktree add` only when `gwq` is unavailable.
- Investigation: Read-only investigation may remain in the current checkout.
- Reuse conditions: Reuse the current checkout for modifications only when the user explicitly asks you to work there or it is already a task-specific, non-default-branch worktree.
- Local changes: Do not mix unrelated local changes into the task. Use another worktree and bring in only task-relevant files.
- Priority: This rule takes precedence over weaker defaults that require a separate worktree only when the current checkout is dirty.

## Plan Specificity

- Applicability: For plans involving repository changes, such as coding, configuration changes, CLI or API changes, data-flow changes, or new tests, do not stop at an abstract approach. Provide a concrete proposal that an implementer can start directly.
- Required items: The final plan must include at least the following:
  - Directories and file paths to change
  - Functions, classes, configuration keys, CLI arguments, and public APIs to add, edit, or delete
  - What to change in each file and how
  - Required test files, test cases to add, and the essential assertions to verify
  - Implementation assumptions, defaults to adopt, and unresolved questions
- Expected granularity: Provide enough detail that an implementer can begin with almost no additional design decisions. Specify function names, types, configuration keys, CLI, data flow, removal targets, and the direction of the changes.
- Code specificity: For important implementation changes, always include a proposed function signature, pseudocode, or short code snippet. Use a roughly 5–20 line fragment when useful.
- Especially required cases: For plans that introduce more implementation decisions, such as parallelization, replacing a concrete API, a data-transformation pipeline, state management, asynchrony, or schema changes, always provide a concrete proposal that identifies the chosen API, processing flow, or function skeleton.
- Per-file writing: Describe the work at a level that conveys which symbol in which file will change and how. For example, replace `build_dataset()` in `src/foo/bar.py` with map-based processing, or add equivalence tests to `tests/test_bar.py`.
- Incomplete plans: Treat a plan that lacks any of the required items above as incomplete. Do not present an incomplete plan as the final plan.
- Handling unknowns: If an important assumption is missing, do not expand the scope on your own; ask only about the ambiguity. However, do not ask about facts that can be learned by reading the repository; investigate first.
- Handling assumptions: If you proceed without waiting for a response, state the assumptions under “Assumptions” or “Premises” and explain how they affect the implementation.

## Protecting Uncommitted Changes

- Treatment of uncommitted changes: Treat uncommitted changes discovered during work as the user's or a concurrent agent's work by default. Do not revert a change unless you can clearly prove that you made it and have explicit permission.
- Assessing changes: Before excluding an uncommitted change from PR scope, reverting it, or deciding it is unnecessary, read its before and after states and use the prose or code context to determine why it was made. Do not assume it is unrelated from the filename or the most recent task alone.
- Improvements: If the before and after states show a quality improvement or a response to feedback, do not revert it on your own; ask the user whether to include it in the PR. In particular, even a one-line writing change may improve information order, citation placement, or the naturalness of the introduction.
- Adjusting PR scope: When you do not want to include an uncommitted change in a PR, do not revert it. Instead, limit what you stage, use another worktree, or ask the user.
- Accidental operations: If you accidentally delete uncommitted changes, report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output. Do not perform additional overwrites before recovery.
