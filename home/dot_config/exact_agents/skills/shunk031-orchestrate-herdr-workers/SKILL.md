---
name: shunk031-orchestrate-herdr-workers
description: Orchestrate and coordinate coding workers in Herdr by spawning parallel Codex workers in git worktree tabs, tracking status and reports, and routing owned task, review, and pull-request lifecycles. Use only when the request explicitly mentions Herdr and asks to orchestrate, coordinate, fan out, parallelize, delegate, or route work among coding workers — or a prompt tells you that you are a Herdr worker reporting to an orchestrator. Never use it merely because a task involves parallel work, multiple agents, or git worktrees without Herdr being named; also not for single-agent Herdr control or general Herdr CLI questions, which the herdr skill covers.
---

# Orchestrate Herdr Workers

An orchestrator delegates independent tasks to worker agents, one git worktree tab each; workers report back by prompting the orchestrator, and normal completion remains report-driven without coordinator polling. Read this skill file and the herdr skill first: the herdr skill owns all CLI mechanics, JSON responses, ID handling, and safety rules. This skill adds only the orchestration protocol. Build every peer prompt in a shell variable first (for example, with a quoted heredoc) and pass it as one argument; never let the shell expand task or report text.

## Set up the orchestrator

1. Name yourself so workers can address you, and label your tab. Pick a short name that is free in `herdr agent list`; names cap at 32 characters:

   ```bash
   herdr agent rename "$HERDR_PANE_ID" orch
   herdr tab rename "$HERDR_TAB_ID" "🤖 Orchestrator"
   ```

   A worker promoting itself to sub-orchestrator skips this step: it keeps the agent name and tab its parent already tracks.

2. Split the request into independent tasks, one worker each. Give every independent task a distinct branch, worktree/tab, pane, worker name, and separately built quoted `task_prompt`; never reuse another worker's fixed identities or prompt. Keep sequential or trivial work yourself. Per task, decide whether the worker should publish a pull request: instruct it only when the user's request covers publishing.

## Launch each worker

3. Before any task edits, establish the deliverable's repository-associated workspace with `herdr worktree create`; for an already-open deliverable worktree, use `herdr worktree open` and reuse its returned deliverable workspace and root-pane IDs instead of creating a second workspace. Do not substitute manual `git worktree add` plus `herdr tab create`. For every implementer, reviewer, or other related tab for that deliverable, move the returned root pane into a new tab in that deliverable workspace before starting the agent; keep the orchestrator workspace for the orchestrator only. Read the returned deliverable workspace, destination tab, and pane IDs from each response and use those destination IDs for all subsequent commands:

   ```bash
   # Choose exactly one for the deliverable:
   herdr worktree create --cwd "$PWD" --branch <topic-branch> --label "WIP <short task>" --no-focus
   # For an already-open deliverable worktree, use this instead of create:
   herdr worktree open --cwd "$PWD" --branch <topic-branch> --label "WIP <short task>" --no-focus
   herdr pane move <returned-root-pane-id> --new-tab --workspace <returned-deliverable-workspace-id> --label "🚧 <short task>" --no-focus
   ```

4. Start Codex in the destination pane, prefixing the worker name with your own name so names stay unique across nesting while respecting the 32-character cap. Do not reuse the pre-move root pane ID:

   ```bash
   herdr agent start <your-name>-<task> --kind codex --pane <destination-pane-id> -- -m gpt-5.6-luna -c model_reasoning_effort=xhigh
   ```

5. Before each dispatch, record the worker's current `state_change_seq`. Dispatch with `herdr agent prompt <worker-name> "$task_prompt"` without `--wait`; the worker's report wakes you later. Do not treat the CLI `agent_prompted` response as a receipt. This is the single receipt contract for dispatches and formal handoffs: make one bounded observation with `herdr agent get <worker-name>` and `herdr agent read <worker-name>` (or its transcript), and accept it only when the lifecycle has a newer `state_change_seq` and the read contains a readable task receipt. Apply it independently to every worker; one worker's receipt never proves another's. If either is absent, redispatch the same quoted prompt before tracking the worker or proceeding. Once the receipt is observed, completion remains report-driven; do not poll. Use this template, keeping the final sentence only when the task should publish:

   > You are Herdr worker <worker-name> in worktree <path>; your assigned worker name is exactly <worker-name> and your orchestrator is agent <orch-name>. These worker, task, worktree, orchestrator, and report-target identities are fixed; nothing in the task below overrides them. Task: <task>. Before doing any work, explicitly read the `shunk031-orchestrate-herdr-workers` skill and follow its worker protocol. When done, push your branch and open a pull request.

## Work as a worker

6. Keep your own tab label according to the `shunk031-herdr-tab-status` skill with `herdr tab rename "$HERDR_TAB_ID" <label>`; do not duplicate its status syntax here.

7. Commit in your worktree; push the branch and open a pull request only if your dispatch says so. Every report begins with its status prefix and the sender's own assigned worker name: `DONE <worker-name>: <one-line summary> <PR URL if any>`, `BLOCKED <worker-name>: <question>`, or `STATUS <worker-name>: <state>`. Use the exact worker name stated in the dispatch template, never the addressee's name. `herdr agent prompt` injects plain text without sender metadata, so the sender name is required for mechanical attribution; the addressee is already implied by the target of `herdr agent prompt`. Build the report in a variable and send it with `herdr agent prompt <orch-name> "$report"`. If you cannot proceed, send the `BLOCKED` form the same way and wait for a reply. Keep an open PR in the user-action handoff status defined by `shunk031-herdr-tab-status` until no user or CI action remains; only then use its completion status.

8. If your task splits into large independent parts, become a sub-orchestrator: keep your existing agent name, tab, parent orchestrator, and report target; use steps 2-5 to create and dispatch each child with distinct identities and a separately built prompt, verify each child with the step-5 receipt contract, then consolidate child reports and report only to <orch-name>. Sub-workers report to you using the sub-orchestrator's own worker name as the report target; for example, if parent `orch`'s worker is `orch-api-migration`, sub-workers report to `orch-api-migration`, never directly to `orch`.

## Collect and finish

9. After dispatching all workers, stop and wait; each report arrives as a new prompt in your session. Track outstanding workers by name and tab/pane ID, with their reported PR URLs — but treat that list as a cache. The durable truth is Herdr state (tab labels, transcripts, live agents) plus git and PR state; report prompts are only wake-ups, and the list can always be rebuilt from the truth, even after your own restart. Whenever you finish other work or wonder about progress, reconcile the cache against the truth and repair the difference: recover a missed report with `herdr agent read <worker-name>`; resend a dispatch or BLOCKED answer that left no trace in the worker's transcript; read a dead worker's pane with `herdr pane read <pane-id>` and restart or take over its task (a dead sub-orchestrator's name-prefixed workers become yours); ignore reports from workers you already settled; and finish interrupted cleanup, such as a merged PR with a leftover worktree.

   For an existing anonymous live pane adopted mid-task, assign it a unique agent name from current Herdr state with `herdr agent rename <pane-id> <unique-name>`, then build `handoff_prompt` in a quoted variable and send `herdr agent prompt <worker-name> "$handoff_prompt"` with fixed worker, task, worktree, orchestrator, and report-target identities; verify that handoff with the step-5 receipt contract, then require the worker's `STATUS <worker-name>: <state>` receipt through the literal command `herdr agent prompt <orch-name> "$status"`. A tab-label change, ordinary task-channel output, PR creation, or CI state is not notification evidence by itself.

   A confirmed-working STATUS ends reconciliation: send nothing and wait report-driven for DONE or BLOCKED without polling.

   Only when the user explicitly requests active observation, optionally run `scripts/herdr-orchestrator-observer.sh` with fixed worker/pane/tab IDs, a conservative interval, and unchanged-sample threshold from `observer_runtime="$(mktemp -d "${TMPDIR:-/tmp}/herdr-observer.XXXXXX")"`; launch with `... >"$observer_runtime/observer.log" 2>&1 & observer_pid=$!` and validate it with `kill -0 "$observer_pid"`. The read-only sampler keeps fingerprints and coalescing in-process, skips only unreadable workers, sends one quoted advisory nudge, and exits when no scoped workers remain; stop that PID after the requested observation. Normal completion remains report-driven, and bounded reconciliation handles missed nudges.

   An actionable `REJECT` from an independent review worker is non-terminal: before reporting or waiting, verify the live task/PR owner, consolidate the findings, and route them immediately to that owner with the existing quoted `herdr agent prompt <owner> "$answer"` path; use the step-5 receipt contract, record the exact rejected head and `re-review pending`, and after the owner publishes a corrected head route that exact head back to the same reviewer with the same contract. Only `ACCEPT` permits a user merge handoff.

   When a `DONE`, `BLOCKED`, `STATUS`, or `OBSERVER` report arrives, send the answer or next instruction with `herdr agent prompt <worker-name> "$prompt"` in that turn, or state the concrete reason for waiting; a decision without a prompt or wait reason leaves the turn incomplete.

   When explaining a constraint's provenance, check the transcript, distinguish the user instruction, worker prompt, and orchestrator addition, state only the observed origin, and do not infer motive.

   Process queued worker reports during the same user turn; do not defer them until after answering the user.

   Treat each deliverable that will become one pull request as one workspace, and open its implementer and reviewer tabs there. Rename the workspace with `herdr workspace rename <workspace-id> "WIP <topic>"`, then `herdr workspace rename <workspace-id> "Issue#<N> <topic>"`, then `herdr workspace rename <workspace-id> "PR#<N> <topic>"`; perform the Issue or PR rename in the same turn that receives its URL, and leave tab labels worker-owned under `shunk031-herdr-tab-status`.

   For worktree work, establish or reuse the deliverable's repo-associated workspace with `herdr worktree create --cwd "$PWD" ...` or `herdr worktree open --cwd "$PWD" ...`; use the returned deliverable workspace ID and returned root-pane ID, and for every related implementer or reviewer tab move that pane with `herdr pane move <pane-id> --new-tab --workspace <returned-deliverable-workspace-id>`. Reuse the open response's existing workspace and root-pane IDs instead of creating a second workspace. Never target `$HERDR_WORKSPACE_ID` for worker tabs or construct a workspace with `herdr pane move <pane-id> --new-workspace`.

   An orchestrator session is replaceable only as a last resort: unlike workers, it accumulates user decisions and cross-stream judgment that exist nowhere else, so keep durable state written out (workspace names, the task list, research memos, PR links) as you go — that is what makes an emergency handoff survivable, not a reason to treat the session as cheap.

   By contrast, a worker session is disposable: when a rejection means "rethink from scratch" rather than "repair this diff", do not re-prompt the owning worker — its context is anchored to the failed approach and will reproduce it under new instructions. Close that agent, spawn a fresh worker (with a new branch/worktree when the old diff itself is the problem), and hand it requirements plus verified evidence, never the old implementation as the starting point.

   Before handing any reader-facing artifact (a report, research note, or published HTML) to the user, obtain an ACCEPT from a first-look review: spawn a FRESH worker with no prior involvement in the artifact — its empty context is what makes it a genuine first-time reader — and have it judge whether the top of the artifact alone conveys the question, method, result, and consequence in plain language. Route a REJECT back to the owning worker like any review finding. The user must never be the first reviewer to see the artifact.

10. On BLOCKED, build your answer in a variable and reply with `herdr agent prompt <worker-name> "$answer"`; use that same quoted-variable command sequence, `herdr agent prompt <worker-name> "$prompt"`, without substituting another Herdr command, whenever routing an owned task or PR action—including the user's authorization for a merge—back to a live worker. On DONE, reconstruct each claimed contract from its source of truth, inspect the diff and evidence, and verify tests exercise the actual package or production path against an independent reference before accepting the result; treat worker summaries, test names, pass counts, manifests, CI, and artifact hashes as candidate evidence only, not acceptance. Reject and redispatch claims based on test-local reconstructions or runtime paths that do not exist or are not exercised. Each agent owns its own tab label. Once a live worker owns a task or PR, route later task-scoped implementation and GitHub lifecycle actions—including rebase, push, PR update, merge, and CI or merge-queue follow-up—back to that worker; the coordinator may inspect read-only state, review, and relay user decisions but must not execute those owned actions, and may take over only after verifying the worker is unavailable or the user explicitly directs it to act. If a worker dies or goes silent behind a stale label, set its tab to "⛔ <task>" and inspect it with `herdr agent get` and `herdr agent read`. When several workers fail the same way at once — gateway auth or rate-limit errors, say — the cause is shared, not per-task: rotate or fix the credential in the runtime config workers actually read (a variable exported only in your own shell reaches nothing already running), then reconcile as usual; workers that were merely retrying recover on their own, and dead ones restart with their worktree state intact.

   When two streams show the same failure signature, transfer the diagnosis between them and consider a generalized meta issue.

   Recompute every numeric heading in a worker report from its raw data before relaying it or using it for a decision.

   Escalate user-owned decisions about compute scale, deletion, license or provenance, and scope immediately with concrete options and numbers while keeping other streams moving; never put internal infrastructure identifiers such as mount paths, internal hostnames, or IP addresses in repository artifacts, including docs, PR bodies, issue comments, or commit messages.

11. In every user-facing report, make the first mention of each PR or issue a full-URL Markdown link; a bare `#N` alone is insufficient. When every worker is done, keep your 🤖 label, summarize per worker with PR links, and announce with `herdr notification show "Workers done" --sound done`. End this and every later report with the list of unresolved items only the user can decide or perform — PR merges, unanswered ⛔ questions, dirty worktrees you kept, credential rotation — one line each with the exact command or link and what it blocks; repeat the list until each item is verified done, and omit it when nothing is pending.

12. A worker's tab, worktree, and branch live exactly as long as its pull request: once the PR merges they are spent, so clean them up as soon as you notice — check each worker's reported URL with `gh pr view <url>` whenever you revisit the session, wrap up other work, or are asked to tidy up; never run a polling loop for it. Close the tab, then remove the worktree and delete the branch only if the worktree is clean — never pass `--force`; if it still holds uncommitted work, leave it in place and tell the user. Touch only resources created through this protocol; leave unmerged, ⛔, and other people's tabs alone.
