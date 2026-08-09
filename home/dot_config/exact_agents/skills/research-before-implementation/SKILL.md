---
name: research-before-implementation
description: Research current official web documentation and representative GitHub implementation code before designing or editing non-trivial work involving third-party tools, libraries, platforms, APIs, configuration formats, or version-dependent behavior. Use for implementation, migration, integration, and configuration tasks where local files or memory alone cannot establish current supported behavior.
---

# Research Before Implementation

Treat research as a gate, not a recommendation. Before any design decision or file edit, complete these tool stages in order:

1. Call the agent's native web search tool (`web_search` in Codex) for current official sources. Inspect documentation, specifications, release notes, and recommended approaches from at least one relevant non-GitHub domain.
2. Only after those results return, call the native web search tool again with results restricted to `github.com`. Inspect representative implementation code or configuration and operational patterns, not only repository descriptions.
3. Compare the documented behavior with the GitHub examples. Resolve version, platform, and maintenance differences before choosing the design.
4. Implement and verify the change based on that evidence.
5. In the final response, name and link the web sources and GitHub examples consulted and state how they affected the implementation.

Do not edit files until both tool calls are complete. Do not substitute memory or local repository inspection for either external research stage. If a required source cannot be accessed, report the limitation before implementation instead of silently skipping the stage.
