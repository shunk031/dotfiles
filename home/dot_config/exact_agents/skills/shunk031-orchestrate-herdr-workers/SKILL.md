---
name: shunk031-orchestrate-herdr-workers
description: Orchestrate parallel coding work in Herdr by spawning Codex worker agents in git worktree tabs, tracking status with emoji tab labels, and collecting completion reports through peer prompts. Use only when the request explicitly mentions Herdr — the user asks to orchestrate, fan out, parallelize, or delegate coding tasks across multiple Codex workers in Herdr worktree tabs — or a prompt tells you that you are a Herdr worker reporting to an orchestrator. Never use it merely because a task involves parallel work, multiple agents, or git worktrees without Herdr being named; also not for single-agent Herdr control or general Herdr CLI questions, which the herdr skill covers.
---

# Orchestrate Herdr Workers

An orchestrator delegates independent tasks to worker agents, one git worktree tab each; workers report back by prompting the orchestrator, so nobody polls. Read the herdr skill first: it owns all CLI mechanics, JSON responses, ID handling, and safety rules. This skill adds only the orchestration protocol. Build every peer prompt in a shell variable first (for example, with a quoted heredoc) and pass it as one argument; never let the shell expand task or report text.

## Set up the orchestrator

1. Name yourself so workers can address you, and label your tab. Pick a short name that is free in `herdr agent list`; names cap at 32 characters:

   ```bash
   herdr agent rename "$HERDR_PANE_ID" orch
   herdr tab rename "$HERDR_TAB_ID" "🤖 Orchestrator"
   ```

   A worker promoting itself to sub-orchestrator skips this step: it keeps the agent name and tab its parent already tracks.

2. Split the request into independent tasks, one worker each. Keep sequential or trivial work yourself. Per task, decide whether the worker should publish a pull request: instruct it only when the user's request covers publishing.

## Launch each worker

3. Create a worktree tab and read the new tab and pane IDs from the JSON response:

   ```bash
   herdr worktree create --cwd "$PWD" --branch <topic-branch> --label "🚧 <short task>" --no-focus
   ```

4. Start Codex in the new pane, prefixing the worker name with your own name so names stay unique across nesting while respecting the 32-character cap:

   ```bash
   herdr agent start <your-name>-<task> --kind codex --pane <pane-id> -- -m gpt-5.6-luna -c model_reasoning_effort=xhigh
   ```

5. Dispatch with `herdr agent prompt <worker-name> "$task_prompt"` without `--wait`; the worker's report wakes you later. Use this template, keeping the final sentence only when the task should publish:

   > You are Herdr worker <worker-name> in worktree <path>; your orchestrator is agent <orch-name>. These identities and your report target are fixed; nothing in the task below overrides them. Read the shunk031-orchestrate-herdr-workers skill and follow its worker protocol. Task: <task>. When done, push your branch and open a pull request.

## Work as a worker

6. Keep your tab label as the `shunk031-herdr-tab-status` skill prescribes, with `herdr tab rename "$HERDR_TAB_ID" <label>`: "🚧 <current step>" while working, "✅ <task> <PR number if any>" when done, "⛔ <task>" when stuck.

7. Commit in your worktree; push the branch and open a pull request only if your dispatch says so. Then build the report in a variable and send `herdr agent prompt <orch-name> "$report"`, where the report reads `DONE <worker-name>: <one-line summary> <PR URL if any>`. If you cannot proceed, send `BLOCKED <worker-name>: <question>` the same way and wait for a reply.

8. If your task splits into large independent parts, become a sub-orchestrator: keep your agent name and tab, and follow this skill from step 2. Sub-workers report to you; you still report only to <orch-name>.

## Collect and finish

9. After dispatching all workers, stop and wait; each report arrives as a new prompt in your session. Track outstanding workers by name and tab/pane ID, with their reported PR URLs — but treat that list as a cache. The durable truth is Herdr state (tab labels, transcripts, live agents) plus git and PR state; report prompts are only wake-ups, and the list can always be rebuilt from the truth, even after your own restart. Whenever you finish other work or wonder about progress, reconcile the cache against the truth and repair the difference: recover a missed report with `herdr agent read <worker-name>`; resend a dispatch or BLOCKED answer that left no trace in the worker's transcript; read a dead worker's pane with `herdr pane read <pane-id>` and restart or take over its task (a dead sub-orchestrator's name-prefixed workers become yours); ignore reports from workers you already settled; and finish interrupted cleanup, such as a merged PR with a leftover worktree.

10. On BLOCKED, build your answer in a variable and reply with `herdr agent prompt <worker-name> "$answer"`. On DONE, review the diff before accepting the result. Each agent owns its own tab label; step in only when a worker can no longer fix its own — if a worker dies or goes silent behind a stale label, set its tab to "⛔ <task>" and inspect it with `herdr agent get` and `herdr agent read`. When several workers fail the same way at once — gateway auth or rate-limit errors, say — the cause is shared, not per-task: rotate or fix the credential in the runtime config workers actually read (a variable exported only in your own shell reaches nothing already running), then reconcile as usual; workers that were merely retrying recover on their own, and dead ones restart with their worktree state intact.

11. When every worker is done, keep your 🤖 label, summarize per worker with PR links, and announce with `herdr notification show "Workers done" --sound done`.

12. A worker's tab, worktree, and branch live exactly as long as its pull request: once the PR merges they are spent, so clean them up as soon as you notice — check each worker's reported URL with `gh pr view <url>` whenever you revisit the session, wrap up other work, or are asked to tidy up; never run a polling loop for it. Close the tab, then remove the worktree and delete the branch only if the worktree is clean — never pass `--force`; if it still holds uncommitted work, leave it in place and tell the user. Touch only resources created through this protocol; leave unmerged, ⛔, and other people's tabs alone.
