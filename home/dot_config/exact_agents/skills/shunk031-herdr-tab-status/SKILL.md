---
name: shunk031-herdr-tab-status
description: Keep the current Herdr worker tab name aligned with task progress using leading status emojis. Use when working in a Herdr-managed pane and starting work, changing the current step, completing a PR, or becoming blocked.
---

# Herdr Tab Status

Apply this ownership contract to the current worker tab. The worker owns its own tab and follows the `herdr` skill to rename it whenever its progress state changes. Put the status emoji only in the tab label; keep workspace and worktree labels emoji-free. Keep the status emoji at the beginning and use a concise task or step name.

- `🚧 <current step>` while work is in progress.
- `✅ <task> <PR number>` after the commit, PR creation, and DONE report are complete.
- `⛔ <task>` when the worker is blocked waiting for an answer. The worker may set this for itself; the orchestrator may set it on the worker's behalf when the worker is silent or dead. Do not change another worker's tab during normal work.

Follow the `herdr` skill's Herdr-environment and current-tab safety requirements before issuing tab commands.
