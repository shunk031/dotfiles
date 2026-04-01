---
name: gh-first-workflow
description: Enforce gh-first GitHub investigation and Conventional Commit output rules. Use when investigating GitHub issues or pull requests, summarizing investigation results, or preparing commit messages.
---

# GH-First Workflow

## Overview

Use this workflow to keep GitHub investigation and commit output consistent with repository policy.

## Read Acknowledgement

- After reading this skill, say: `🐙 私は gh-first-workflow を読みました。`

## Workflow

1. Start issue/PR investigation with `gh` commands.
2. Use `web` only when `gh` cannot provide required details.
3. Collect URLs for every issue/PR that was inspected.
4. Include inspected URLs in the response.
5. Write commit messages in Conventional Commit format.

## Output Checklist

- State that `gh` was used first.
- State why `web` was used when fallback was necessary.
- Include inspected issue/PR URLs.
- Keep commit subject in Conventional Commit form: `<type>(<scope>): <summary>`.

Use [gh-git-rules.md](references/gh-git-rules.md) for command examples and commit-type guidance.
