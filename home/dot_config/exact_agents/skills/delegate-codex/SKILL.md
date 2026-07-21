---
name: delegate-codex
description: 実装タスクを herdr の新しいラベル付き tab 上の使い捨て実装者 Codex に agmsg 経由で委譲する。どのリポジトリでも、実装・修正・コミット・push・PR 作成を任せるとき、「codex にやらせて」「実装者に依頼」「委譲して」のとき、および main が自分でコードを書き始めそうなときに必ず使う。相談相手を立てて、壁打ち用に codex を立てて、などユーザー相談用 Codex が必要なときにも使う。
---

# Delegate Codex

## Overview

Delegate implementation work to a disposable Codex implementer in a fresh Herdr tab and coordinate through agmsg. Keep repository changes, push, PR creation, and CI confirmation on the implementer side while `main` stays focused on task framing, monitoring, review, approval, merge decisions, and cleanup.

This skill is intentionally repository-agnostic. Do not encode local-only settings here. For environment-specific Codex trust, launch options, git, or GitHub behavior, read `~/.agents/AGENTS-private.md` and follow the relevant section.

## Always Delegate

Use this skill for any write work in any repository, including this dotfiles repository itself. Code changes, documentation edits, configuration or dotfiles changes, commits, pushes, and pull request creation or updates all go through a disposable implementer. `main` must not commit or push directly, even for a one-line change and even when the repository is not the current project.

If the user explicitly names `$delegate-codex` or `delegate-codex`, treat this skill as the controlling workflow for the turn. Do not substitute `gh-workflow-manager`, a generic worker, or any other PR agent merely because the task includes GitHub, push, pull request, or CI work. If Codex-only PR or GitHub workflow guidance appears to conflict, route the whole write and PR workflow through the disposable Codex described by this skill, and keep `main` as coordinator, reviewer, and explicit-merge executor only. Before spawning any agent for write or PR work, state the selected skill and agent in a short user-facing update.

Task size never creates an exception. "Small enough to do myself" is not a valid reason to skip delegation.

At the start of every new delegation, re-open this `SKILL.md` and follow the current procedure from the skill. Do not reproduce the delegation flow from memory; remembered steps drift from the source of truth.

`main` may directly perform read-only investigation, send or receive agmsg messages, monitor, nudge, or clean up Herdr-managed implementers, run GitHub read operations, and execute a merge only when the user explicitly instructs `main` to merge that specific pull request.

This rule is for the coordinator role. If the current agent is already acting as an `impl-<task-slug>` implementer for a delegated task, complete that assigned work in its own task worktree instead of recursively spawning another implementer.

## Consultation Mode

Use Consultation Mode when the user wants a disposable Codex consultant for direct discussion instead of write work. Consultation Mode does not replace the implementer flow because it has no write authority; if the consultation produces implementation work, delegate that follow-up work to an implementer with the standard workflow.

Create one consultant per consultation. Use `consult-<topic-slug>` for the agmsg role and `consult: <topic-slug>` for the Herdr tab label.

Create a read-only anchor worktree for the consultation before spawning:

```shell
gwq add -b consult/<topic-slug>
PROJECT=$(gwq get consult/<topic-slug>)
```

Spawn the consultant through the same Herdr wrapper used in [Spawn](#spawn):

```shell
TEAM=$(basename -s .git "$(git remote get-url origin)")
NAME=consult-<topic-slug>
scripts/spawn-codex-tab.sh "$TEAM" "$NAME" "$PROJECT"
```

The `PROJECT` must be the dedicated read-only anchor worktree created for the consultation. A dedicated path is required even for consultation because agmsg resolves identity per `(project, type)` pair and may not handle multiple Codex identities in the same project path reliably.

Send the initial task message from `main` to the consultant with agmsg:

```shell
~/.agents/skills/agmsg/scripts/send.sh "$TEAM" main "$NAME" "<message>"
```

When the message contains Markdown code fences, pass it with single quotes or through a variable or heredoc; do not place triple-backtick content directly inside a Bash double-quoted string because backticks trigger command substitution.

Use this template and fill in every placeholder before sending:

````markdown
## Consultation Topic

<topic and the background summary already known by main>

## Constraints

- Treat this repository as read-only. Do not make repository changes, commits, pushes, pull requests, GitHub write operations, or any other write operation.
- Read-only investigation, local file inspection, and search are allowed when they help the discussion.

## Conversation Policy

The user will appear directly in this pane after startup. Your primary job is to answer and discuss with the user in this pane. Do not send intermediate status reports to main.

After reading this briefing, print a short ready message in the pane such as "相談の準備ができました。どうぞお話しください" and wait for the user. Do not send an agmsg reply to main for this readiness signal.

## Completion Protocol

When the user says "相談おわりました" or any close variant or synonym, summarize the consultation for main. Include the conclusion, decisions, unresolved questions, and recommended actions in a structured message.

Send that summary with:

```shell
~/.agents/skills/agmsg/scripts/send.sh <team> consult-<topic-slug> main "<summary>"
```

Use team `<team>` and your role `consult-<topic-slug>`. After sending the summary, tell the user only: "結果を親エージェントに引き継ぎました". Do not show the user the words agmsg, Herdr, pane id, or any internal command.
````

After spawning and sending the task message, make exactly one successful pre-consultation nudge so the consultant reads the briefing before the user enters the pane:

```shell
scripts/nudge-codex.sh <pane_id> "inbox を確認して相談準備をしてください"
```

If this nudge exits with code 3 because Codex is still booting or not idle, follow [Nudge Rules](#nudge-rules) and retry after the pane reaches `idle` or `done` until this one pre-consultation nudge succeeds.

Wait for the pane to transition to working, finish reading the briefing, print its ready message, and return to idle by using the same non-intrusive waiting pattern as [Monitoring](#monitoring). Only after this readiness confirmation, tell the user in plain language:

```text
相談用のタブ `consult: <topic-slug>` を開きました。そちらで直接お話しください。終わったら「相談おわりました」と伝えてください。
```

Treat the consultation pane as user-occupied from the moment this user-facing guidance is sent. Do not nudge it again, read the pane transcript, or otherwise operate it with Herdr while the consultation is active. Wait for the result through the `main` agmsg inbox as described in [Monitoring](#monitoring), then reflect the received consultation result in the next work. If the user confirms outside the pane that the consultation is finished without a summary, `main` may proceed to cleanup without waiting for a consultant summary.

After receiving the consultation summary, ask the user whether they need any additional consultation before cleanup. If there is no additional consultation, the consultation's user-occupied state ends and the normal [Cleanup](#cleanup) procedure is allowed. Close the Herdr tab and reset the consultant registration, then remove the read-only anchor worktree and delete the branch created for the anchor worktree:

```shell
gwq remove consult/<topic-slug>
git branch -D consult/<topic-slug>
```

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
scripts/spawn-codex-tab.sh "$TEAM" "$NAME" "$PROJECT"
```

The wrapper must return only machine-readable placement lines:

```text
tab_id=<herdr-tab-id>
pane_id=<herdr-pane-id>
```

If it prints `spawned ... in tmux`, `spawned ... in a new terminal window`, or any other agmsg `spawn.sh` placement text, treat that as a failed spawn. Do not send a task message; fix the wrapper or restart with a clean Herdr tab first.

The wrapper creates the Herdr tab directly and pre-registers the Codex identity with agmsg. It intentionally does not call `~/.agents/skills/agmsg/scripts/spawn.sh`, because `spawn.sh` prefers tmux placement when `$TMUX` is set and can silently create a narrow pane instead of the required Herdr tab.

The wrapper injects environment-specific Codex CLI arguments from agmsg's per-type `spawn_options.yaml` using the same `codex:` semantics as `~/.agents/skills/agmsg/scripts/spawn.sh`; a missing file or missing `codex:` section is a no-op.
Set `HERDR_CODEX_BIN` when the local environment needs a Codex wrapper instead of the plain `codex` executable.
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
