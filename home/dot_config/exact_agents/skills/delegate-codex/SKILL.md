---
name: delegate-codex
description: 実装タスクを herdr の新しいラベル付き tab 上の使い捨て実装者 Codex に agmsg 経由で委譲する。どのリポジトリでも、実装・修正・コミット・push・PR 作成を任せるとき、「codex にやらせて」「実装者に依頼」「委譲して」のとき、および main が自分でコードを書き始めそうなときに必ず使う。
---

# Delegate Codex

## Overview

Delegate implementation work to a disposable Codex implementer in a fresh Herdr tab and coordinate through agmsg. Keep repository changes, push, PR creation, and CI confirmation on the implementer side while `main` stays focused on task framing, monitoring, review, approval, merge decisions, and cleanup.

This skill is intentionally repository-agnostic. Do not encode local-only settings here. For environment-specific Codex trust, launch options, git, or GitHub behavior, read `~/.agents/AGENTS-private.md` and follow the relevant section.

## Always Delegate

When `main` is about to perform implementation work, repository edits, commits, pushes, PR creation or updates, or CI confirmation for any task, use this skill and delegate the work to a fresh implementer instead of doing the work directly.

This applies even when the change looks small, documentation-only, or routine. `main` may inspect context, frame the task, monitor progress, review the resulting diff, and decide whether more changes are needed, but the disposable implementer owns the repository modifications and GitHub workflow.

This rule is for the coordinator role. If the current agent is already acting as an `impl-<task-slug>` implementer for a delegated task, complete that assigned work in its own task worktree instead of recursively spawning another implementer.

## Roles And Naming

- Team: derive the agmsg team name from the repository remote, not from the worktree directory:

  ```shell
  basename -s .git "$(git remote get-url origin)"
  ```

  Worktree directories managed by `gwq` may include `=branch` suffixes, so directory names are not stable team names.
- Coordinator role: `main`.
- Implementer role: `impl-<task-slug>`.
- Herdr tab label: `impl: <task-slug>`.
- Use a short, descriptive task slug such as `fix-ci`, `add-login-test`, or `delegate-codex-global`.

## Ownership Rules

- Disposable implementer: create a fresh implementer for each task. Use one task, one implementer, one worktree, and one Herdr tab. Do not keep or share a long-lived generic `impl` role.
- Worktree boundary: use one worktree for one implementer. Do not join multiple Codex identities to the same project path because agmsg inbox polling may select only one matching identity for a `(project, type)` pair.
- User ownership: if the user starts giving direct instructions in an implementer's pane, treat that instance as user-occupied. From that point, `main` must not operate that pane with Herdr and must not send agmsg tasks to that role. Spawn a new implementer for any new task.
- Occupancy check: before nudging a pane, inspect the recent transcript:

  ```shell
  herdr pane read <pane_id> --source recent-unwrapped
  ```

  If the transcript shows a task, plan, or conversation that `main` does not remember assigning, treat the pane as user-occupied and spawn a new implementer instead of nudging it.

## Spawn

Use the bundled wrapper to create the implementer in a new Herdr tab:

```shell
TEAM=$(basename -s .git "$(git remote get-url origin)")
NAME=impl-<task-slug>
PROJECT=<task-worktree-path>
scripts/spawn-codex-tab.sh "$TEAM" "$NAME" "$PROJECT" [boot-prompt]
```

The wrapper calls `~/.agents/skills/agmsg/scripts/spawn.sh` with a Herdr terminal template. Environment-specific Codex CLI arguments are injected by agmsg from `~/.agmsg/config/spawn_options.yaml`; see `~/.agents/AGENTS-private.md` for the local values and setup steps.
Set `HERDR_SPAWN_ENV_KEYS` to a space-separated list of environment variable names to pass selected values through to `herdr tab create` as `--env KEY=VALUE`.

Before the first spawn in a new project or worktree, confirm the Codex trust settings for that path; see `~/.agents/AGENTS-private.md` for the local trust procedure. In tmux environments, agmsg `spawn.sh` also supports its standard `--split` mode, but this skill's Herdr wrapper creates a new labeled tab so it does not split the user's current pane.

Before launching the implementer, inspect the worktree's messaging identity:

```shell
~/.agents/skills/agmsg/scripts/whoami.sh "$PROJECT" codex
```

If another Codex identity is already registered for this project path, do not reuse that worktree for a new implementer. Create a fresh worktree or clean up the stale registration first.

## Task Message

Send the task from `main` to the implementer with agmsg:

```shell
~/.agents/skills/agmsg/scripts/send.sh "$TEAM" main "$NAME" "<message>"
```

Use this template:

```markdown
## 背景

## 変更対象

## 完了条件

## 報告
```

In `## 変更対象`, list concrete file paths and ownership boundaries. In `## 完了条件`, list the exact verification commands or CI expectations, and always include that completion means PR creation plus green CI only: the implementer must not merge; `main` reviews and leaves the merge decision to the user. In `## 報告`, ask the implementer to reply with the PR URL, CI state, and any review notes. The implementer's own GitHub workflow guidance is responsible for commit, push, PR, and CI discipline.

## Nudge Rules

- Nudge only through the bundled helper:

  ```shell
  scripts/nudge-codex.sh <pane_id> "inbox を確認して着手してください"
  ```

- Do not force-queue messages into a working pane with `herdr pane send-keys <pane_id> tab`. agmsg messages remain in the recipient's inbox, so wait until the Codex pane is idle or done and nudge then.
- If `nudge-codex.sh` exits with code 3, the pane is not idle or done. Wait until the pane's `agent_status` is `idle` or `done`, then retry the nudge.
- Always run the occupancy check before a nudge. If the pane has become user-occupied, stop operating it and spawn a fresh implementer.

## Monitoring

Wait for the implementer's current turn to finish with:

```shell
scripts/wait-pane.sh <pane_id>
```

Check the coordinator inbox for reports:

```shell
~/.agents/skills/agmsg/scripts/inbox.sh "$TEAM" main
```

For long-running work, repeat non-intrusive checks: wait for the pane status, read the inbox, review reported progress, and nudge only when the pane is idle or done and still owned by `main`.

## Review Split

- Implementer: make the repository changes, run local verification, commit, confirm HTTPS push configuration when required by the environment, push, open or update the PR, and monitor CI until it is green or clearly blocked.
- `main`: frame the task, monitor progress, review the diff and CI report, request follow-up changes when needed, approve or make the merge decision, and clean up the disposable implementer after the work is accepted.
- Merge execution: merge only when the user explicitly instructs `main` to merge that specific PR. Do not carry forward an apparent blanket approval from prior context to a new PR, and do not let `main` or the implementer self-merge because the change looks small or routine.

Keep push, PR creation or update, and CI confirmation on the implementer side. The implementer Codex should use its own GitHub workflow guidance for git and GitHub write operations.

## Cleanup

After the task is complete, reviewed, and no further changes are needed:

1. Close the Herdr tab created for the implementer:

   ```shell
   herdr tab close <tab_id>
   ```

2. Remove the disposable Codex agmsg registration:

   ```shell
   ~/.agents/skills/agmsg/scripts/reset.sh "$PROJECT" codex "$NAME"
   ```

Do not use `~/.agents/skills/agmsg/scripts/despawn.sh --force` for Herdr-launched implementers. The Herdr tab is created outside agmsg's spawn placement record, so `despawn.sh --force` has no reliable placement to tear down.

Do not clean up user-occupied instances. Leave their tab and agmsg registration intact.
