---
name: setup-agent-docs
description: Guidance-document wiring pattern for making a repository ready for coding agents: use AGENTS.md as the source of truth and make CLAUDE.md a symlink. Use this skill for new repository agent setup, making a repository coding-agent ready, creating, converting, or organizing AGENTS.md and CLAUDE.md, adding repo-local skills, or requests to prepare agent documentation. Also use it to verify the wiring when creating only CLAUDE.md or only AGENTS.md.
---

# setup-agent-docs

The standard pattern for wiring agent documentation in a repository. It ensures that multiple coding agents read the same source and prevents duplication and drift.

## Wiring Rules

- AGENTS.md as the source of truth: Place `AGENTS.md` at the repository root and write all agent conventions and procedures there. Put a read acknowledgement marker at the beginning:

  ```markdown
  > [!NOTE]
  > After reading this AGENTS.md, say: 🤖 I read the AGENTS.md for <owner>/<repo>.
  ```

- Write only repository-specific content: Do not repeat rules already in global `~/.agents/AGENTS.md`, such as mandatory uv usage, worktree policy, or error-handling policy. Repeating them causes drift when they are updated.

- Make CLAUDE.md a relative symlink to AGENTS.md: Do not make it a regular file containing `@AGENTS.md`.

  ```shell
  ln -s AGENTS.md CLAUDE.md
  git add CLAUDE.md   # Verify mode 120000 with: git ls-files -s CLAUDE.md
  ```

  Why use a symlink: Claude Code and other tools read the same source, preventing differences in import-syntax support and copied-content drift.

- Wiring repo-local skills: Place each skill's source of truth at `.agents/skills/<name>/SKILL.md` and commit `.claude/skills` as a relative symlink.

  ```shell
  mkdir -p .agents/skills
  ln -s ../.agents/skills .claude/skills
  ```

  Even coding agents without Claude's skill mechanism can follow the same procedure because SKILL.md is ordinary Markdown; reference `.agents/skills/<name>/SKILL.md` from AGENTS.md.

- Private boundary: Never write private information, such as internal networks, launch profiles, or proxy details, in the repository. Where needed, add only a pointer such as “For environment-specific settings, refer to the relevant section of `~/.agents/AGENTS-private.md`.” Because the global AGENTS.md instructs agents to read AGENTS-private.md, the pointer is sufficient.

## Reference Implementation

https://github.com/haralab-uec/kitada-experiments — an example using `AGENTS.md`, `CLAUDE.md` (symlink), `.agents/skills/`, and `.claude/skills` (symlink).
