---
name: shunk031-research-before-implementation
description: Research current official web documentation and representative GitHub implementation code before designing or editing non-trivial work involving third-party tools, libraries, platforms, APIs, configuration formats, or version-dependent behavior. Use for implementation, migration, integration, and configuration tasks where local files or memory alone cannot establish current supported behavior.
---

# Research Before Implementation

Treat research as a gate, not a recommendation. Before any design decision or file edit, complete these tool stages in order:

1. Use an available web-research capability for current official sources. Rely on the capability the current agent host actually exposes; do not assume a particular tool name or namespace. Inspect documentation, specifications, release notes, and recommended approaches from at least one relevant non-GitHub domain.
2. Only after those results return, use a GitHub search or inspect `github.com` sources. Inspect representative implementation code or configuration and operational patterns, not only repository descriptions.
3. Compare the documented behavior with the GitHub examples. Resolve version, platform, and maintenance differences before choosing the design.
4. Implement and verify the change based on that evidence.
5. In the final response, name and link the web sources and GitHub examples consulted and state how they affected the implementation. The final response must list at least one official non-GitHub URL and one representative GitHub URL, and explain how each source affected the implementation. The GitHub URL must point directly to implementation code or configuration, not only a README, release, or marketplace page.

Do not edit files until both tool calls are complete. Do not substitute memory or local repository inspection for either external research stage. If either stage fails, returns no usable sources, or cannot be accessed, stop before designing or editing; report the limitation and ask the user whether to retry with another available native-search-capable session, proceed only with explicitly labeled fallback evidence for non-implementation triage, or pause the task. Do not continue with an implementation until the required research stage is satisfied or the task is explicitly re-scoped so this skill no longer applies.
