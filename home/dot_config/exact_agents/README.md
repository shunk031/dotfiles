- This directory is the canonical source for `~/.agents`.
- [AGENTS.md](AGENTS.md) is the shared guidance used directly by `~/.agents/AGENTS.md`, imported from `~/.claude/CLAUDE.md` with `@~/.agents/AGENTS.md`, and read first from `~/.codex/AGENTS.md` before `~/.codex/AGENTS.codex-only.md`.
- [home/exact_dot_agents/](../../exact_dot_agents/) is only the adapter layer that exposes this source in the applied home layout.
- The design keeps edits in one git-friendly place while preserving the familiar home path.
- Edit files here; the adapter keeps the home path stable.

## Layout Overview

```mermaid
flowchart LR
  subgraph RUNTIME["runtime"]
    U_CLAUDE["Claude Code"]
    U_CODEX["Codex"]
  end

  subgraph HOME["$HOME"]
    H_CLAUDE(["~/.claude/CLAUDE.md"])
    H_CLAUDE_SKILLS(["~/.claude/skills/"])

    H_SHARED(["~/.agents/AGENTS.md"])
    H_SHARED_SKILLS(["~/.agents/skills/"])

    H_CODEX(["~/.codex/AGENTS.md"])
    H_CODEX_ONLY(["~/.codex/AGENTS.codex-only.md"])
    H_CODEX_AGENTS(["~/.codex/agents/"])
  end

  subgraph CHEZMOI["chezmoi source state"]
    direction LR

    subgraph ADAPTER["adapter templates"]
      A_CLAUDE["home/dot_claude/symlink_CLAUDE.md.tmpl"]
      A_CLAUDE_SKILLS["home/dot_claude/symlink_skills.tmpl"]

      A_SHARED["home/exact_dot_agents/symlink_AGENTS.md.tmpl"]
      A_SHARED_SKILLS["home/exact_dot_agents/symlink_skills.tmpl"]

      A_CODEX["home/dot_codex/symlink_AGENTS.md.tmpl"]
      A_CODEX_ONLY["home/dot_codex/symlink_AGENTS.codex-only.md.tmpl"]
      A_CODEX_AGENTS["home/dot_codex/symlink_agents.tmpl"]
    end

    subgraph CANONICAL["canonical source"]
      S_CLAUDE["home/dot_config/claude/CLAUDE.md"]

      S_SHARED["home/dot_config/exact_agents/AGENTS.md"]
      S_SHARED_SKILLS["home/dot_config/exact_agents/skills/"]

      S_CODEX["home/dot_config/codex/AGENTS.md"]
      S_CODEX_ONLY["home/dot_config/codex/AGENTS.codex-only.md"]
      S_CODEX_AGENTS["home/dot_config/codex/agents/"]
    end
  end

  U_CLAUDE --> H_CLAUDE
  U_CLAUDE --> H_CLAUDE_SKILLS
  H_CLAUDE --> H_SHARED

  U_CODEX --> H_CODEX
  U_CODEX --> H_SHARED_SKILLS
  U_CODEX --> H_CODEX_AGENTS
  H_CODEX --> H_SHARED --> H_CODEX_ONLY

  H_CLAUDE --> A_CLAUDE --> S_CLAUDE
  H_CLAUDE_SKILLS --> A_CLAUDE_SKILLS --> S_SHARED_SKILLS

  H_SHARED --> A_SHARED --> S_SHARED
  H_SHARED_SKILLS --> A_SHARED_SKILLS --> S_SHARED_SKILLS

  H_CODEX --> A_CODEX --> S_CODEX
  H_CODEX_ONLY --> A_CODEX_ONLY --> S_CODEX_ONLY
  H_CODEX_AGENTS --> A_CODEX_AGENTS --> S_CODEX_AGENTS

  classDef runtime fill:#f5f5f5,stroke:#444,color:#111;
  classDef agents fill:#eef7ee,stroke:#4f7a4f,color:#111;
  classDef claude fill:#eef4ff,stroke:#4a6fa5,color:#111;
  classDef codex fill:#fff3e8,stroke:#b26b2a,color:#111;

  class U_CLAUDE,U_CODEX runtime;
  class H_SHARED,H_SHARED_SKILLS,A_SHARED,A_SHARED_SKILLS,S_SHARED,S_SHARED_SKILLS agents;
  class H_CLAUDE,H_CLAUDE_SKILLS,A_CLAUDE,A_CLAUDE_SKILLS,S_CLAUDE claude;
  class H_CODEX,H_CODEX_ONLY,H_CODEX_AGENTS,A_CODEX,A_CODEX_ONLY,A_CODEX_AGENTS,S_CODEX,S_CODEX_ONLY,S_CODEX_AGENTS codex;
```
