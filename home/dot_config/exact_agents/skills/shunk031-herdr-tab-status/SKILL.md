---
name: shunk031-herdr-tab-status
description: Choose and update the current Herdr worker tab name with exact leading status emojis for active work, blocked work, user handoffs, and completion. Use whenever a Herdr tab label or its status meaning must be chosen or updated.
---

# Herdr Tab Status

The worker owns its current tab and follows the `herdr` skill to rename it whenever progress changes. The leading emoji is the primary signal because the task label may be truncated. Put status only in the tab label; keep workspace and worktree labels emoji-free.

Use exactly these states:

- `🚧 <current step>` means work is actively progressing, including a live retry or diagnostic run.
- `⛔ <next action>` means the worker cannot progress or close: it is waiting for an answer, review, approval, or merge; an external dependency blocks it; or it was stopped/superseded and awaits handoff or cleanup.
- `✅ <task> <PR number>` means worker work and the required handoff are complete, with no action remaining.

A pending review or merge is blocked work, not active work or completion; use a next-action label such as `⛔ review and merge PR <number>`. The worker renames its own tab. The orchestrator may set the blocked label only for a silent or dead worker and must not change another live worker's tab during normal work.

When asked to choose a label, put the literal label on the first line, then explain it.

For a BLOCKED report, the worker renames its own tab before reporting:

```text
herdr tab rename "$HERDR_TAB_ID" "⛔ <next action>"
herdr agent prompt <orchestrator> "BLOCKED <worker>: <reason>"
```

Follow the `herdr` skill's Herdr-environment and current-tab safety requirements before issuing tab commands.
