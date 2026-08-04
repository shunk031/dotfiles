In this repo, this directory is the editable shared source for agent guidance that is exposed as `~/.agents` through adapter templates. The `exact_` segment in this path is a chezmoi source-state attribute, not a generic "canonical source" naming convention. See the official chezmoi reference for [Source state attributes](https://www.chezmoi.io/reference/source-state-attributes/).

In chezmoi, `dot_` changes a target name to start with `.`, while `exact_` removes entries in the target directory that are not explicitly managed in the source state. This repo does not apply `.config/agents` directly: [home/.chezmoitemplates/chezmoiignore.d/common](../../.chezmoitemplates/chezmoiignore.d/common) ignores that target, while [home/exact_dot_agents/](../../exact_dot_agents/) provides the home-facing `~/.agents` adapter.

[AGENTS.md](AGENTS.md) is the shared guidance used directly by `~/.agents/AGENTS.md`, imported from `~/.claude/CLAUDE.md` with `@~/.agents/AGENTS.md`, and referenced from `~/.codex/AGENTS.md`. Shared long-form agent instructions live in [agents/](agents/) and are exposed as `~/.agents/agents`; Claude and Codex wrappers explicitly tell each tool to read the same shared Markdown first. Edit files here; the adapter keeps the home path stable.

## Optional Private Guidance

Private, environment-specific guidance is stored in the separate `dotfiles-private` checkout at `~/.local/share/chezmoi-private/.agents/AGENTS-private.md`. That file is outside the private repository's chezmoi source root (`home/`), so it is repository support content rather than an independently applied private source-state entry.

This public repository owns the home-facing `~/.agents` exact directory. Its [home/exact_dot_agents/symlink_AGENTS-private.md.tmpl](../../exact_dot_agents/symlink_AGENTS-private.md.tmpl) adapter therefore exposes the private file as `~/.agents/AGENTS-private.md`. If the private checkout or file is absent, the link is not readable and [AGENTS.md](AGENTS.md) instructs agents to continue with only the public guidance. Edit private instructions in the private repository; edit the public adapter only when changing this wiring.

## Skill Pool and Subscription Policy

`~/.agents/skills` is a real directory: the shared skills pool. Each repo-managed skill under `home/dot_config/exact_agents/skills/<name>/` is exposed there through its own `home/exact_dot_agents/skills/symlink_<name>.tmpl` adapter template, so adding a skill to the pool means adding one skill directory plus one shared-pool symlink template, not editing a `.gitignore` allowlist.

Gemini receives the same repo-managed skills through per-skill templates under `home/dot_gemini/config/skills/symlink_<name>.tmpl`. Keep those templates in sync with the shared pool templates; do not restore the old whole-directory `home/dot_gemini/config/symlink_skills.tmpl` adapter.

`~/.claude/skills` is also a real directory, but it is Claude-only and unmanaged by chezmoi: `npx skills add --agent claude-code` and similar installers write generated skills directly there without touching the chezmoi source tree. On every `chezmoi apply`, [home/.chezmoiscripts/common/run_after_90-link-shared-skills.sh.tmpl](../../.chezmoiscripts/common/run_after_90-link-shared-skills.sh.tmpl) subscribes `~/.claude/skills` to the pool: it symlinks every pool entry into `~/.claude/skills`, skips (and warns about) any name that already exists there as a real, installer-written directory, and prunes pool symlinks whose pool entry has since been removed.

To make an installer-added skill repo-managed, move its directory into `home/dot_config/exact_agents/skills/` and add matching `home/exact_dot_agents/skills/symlink_<name>.tmpl` and `home/dot_gemini/config/skills/symlink_<name>.tmpl` templates; the next `chezmoi apply` then relinks it as a shared pool entry and Gemini skill.

The diagram below describes this repository's source-of-truth layout, not the meaning of chezmoi's `exact_` attribute itself.

## Layout Overview

```mermaid
flowchart LR
  subgraph RUNTIME["runtime"]
    U_CLAUDE["Claude Code"]
    U_CODEX["Codex CLI"]
    U_INSTALLER["skill installer (e.g. npx skills add)"]
    U_GEMINI["Gemini CLI"]
  end

  subgraph HOME["$HOME"]
    H_CLAUDE(["~/.claude/CLAUDE.md"])
    H_CLAUDE_AGENTS(["~/.claude/agents/"])
    H_CLAUDE_SKILLS(["~/.claude/skills/ (real dir)"])

    H_CODEX(["~/.codex/AGENTS.md"])
    H_CODEX_AGENTS(["~/.codex/agents/"])

    H_SHARED(["~/.agents/AGENTS.md"])
    H_SHARED_AGENTS(["~/.agents/agents/"])
    H_SHARED_SKILLS(["~/.agents/skills/ (real dir, shared pool)"])

    H_GEMINI_SKILLS(["~/.gemini/config/skills/"])
  end

  subgraph CHEZMOI["chezmoi source state"]
    direction LR

    subgraph ADAPTER["adapter templates"]
      A_CLAUDE["home/dot_claude/symlink_CLAUDE.md.tmpl"]
      A_CLAUDE_AGENTS["home/dot_claude/symlink_agents.tmpl"]

      A_CODEX["home/dot_codex/symlink_AGENTS.md.tmpl"]
      A_CODEX_AGENTS["home/dot_codex/symlink_agents.tmpl"]

      A_SHARED["home/exact_dot_agents/symlink_AGENTS.md.tmpl"]
      A_SHARED_AGENTS["home/exact_dot_agents/symlink_agents.tmpl"]
      A_SHARED_SKILL["home/exact_dot_agents/skills/symlink_<name>.tmpl (one per skill)"]

      A_GEMINI_SKILLS["home/dot_gemini/config/skills/symlink_<name>.tmpl (one per skill)"]
    end

    subgraph CANONICAL["canonical source"]
      S_CLAUDE["home/dot_config/claude/CLAUDE.md"]
      S_CLAUDE_AGENTS["home/dot_config/claude/agents/"]

      S_CODEX["home/dot_config/codex/AGENTS.md"]
      S_CODEX_AGENTS["home/dot_config/codex/agents/"]

      S_SHARED["home/dot_config/exact_agents/AGENTS.md"]
      S_SHARED_AGENTS["home/dot_config/exact_agents/agents/"]
      S_SHARED_SKILLS["home/dot_config/exact_agents/skills/<name>/"]
    end

    RUNAFTER["home/.chezmoiscripts/common/run_after_90-link-shared-skills.sh.tmpl"]
  end

  U_CLAUDE --> H_CLAUDE
  U_CLAUDE --> H_CLAUDE_AGENTS
  U_CLAUDE --> H_CLAUDE_SKILLS
  U_CODEX --> H_CODEX
  U_CODEX --> H_CODEX_AGENTS
  U_CODEX --> H_SHARED_SKILLS
  U_INSTALLER --> H_CLAUDE_SKILLS
  U_GEMINI --> H_GEMINI_SKILLS
  H_CLAUDE --> H_SHARED
  H_CLAUDE_AGENTS --> H_SHARED_AGENTS
  H_CODEX --> H_SHARED
  H_CODEX_AGENTS --> H_SHARED_AGENTS

  H_CLAUDE --> A_CLAUDE --> S_CLAUDE
  H_CLAUDE_AGENTS --> A_CLAUDE_AGENTS --> S_CLAUDE_AGENTS

  H_CODEX --> A_CODEX --> S_CODEX
  H_CODEX_AGENTS --> A_CODEX_AGENTS --> S_CODEX_AGENTS

  H_SHARED --> A_SHARED --> S_SHARED
  H_SHARED_AGENTS --> A_SHARED_AGENTS --> S_SHARED_AGENTS
  H_SHARED_SKILLS --> A_SHARED_SKILL --> S_SHARED_SKILLS

  H_SHARED_SKILLS --> RUNAFTER --> H_CLAUDE_SKILLS
  H_GEMINI_SKILLS --> A_GEMINI_SKILLS --> S_SHARED_SKILLS

  classDef runtime fill:#f5f5f5,stroke:#444,color:#111;
  classDef agents fill:#eef7ee,stroke:#4f7a4f,color:#111;
  classDef claude fill:#eef4ff,stroke:#4a6fa5,color:#111;
  classDef codex fill:#f2f0ff,stroke:#6750a4,color:#111;

  class U_CLAUDE,U_CODEX,U_INSTALLER,U_GEMINI runtime;
  class H_SHARED,H_SHARED_AGENTS,H_SHARED_SKILLS,A_SHARED,A_SHARED_AGENTS,A_SHARED_SKILL,S_SHARED,S_SHARED_AGENTS,S_SHARED_SKILLS,RUNAFTER agents;
  class H_CLAUDE,H_CLAUDE_AGENTS,H_CLAUDE_SKILLS,A_CLAUDE,A_CLAUDE_AGENTS,S_CLAUDE,S_CLAUDE_AGENTS claude;
  class H_CODEX,H_CODEX_AGENTS,A_CODEX,A_CODEX_AGENTS,S_CODEX,S_CODEX_AGENTS codex;
  class H_GEMINI_SKILLS,A_GEMINI_SKILLS runtime;
```
