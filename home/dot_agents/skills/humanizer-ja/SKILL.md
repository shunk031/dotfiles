---
name: humanizer-ja
description: Rewrite Japanese prose so it sounds like a person wrote it, not an LLM. Use when polishing blog posts, notes, emails, documents, social posts, or chat replies that feel AI-generated, and when the user asks to humanize text, remove AI-like phrasing, add voice, or make Japanese read more naturally.
---

# Humanizer JA

## Overview

Rewrite AI-sounding Japanese into natural prose with clearer voice, sharper specifics, and less template wording.
Preserve the original meaning and audience. Remove AI patterns, then replace them with human choices.

## Workflow

1. Identify the text's purpose, audience, and target tone from the surrounding context. Infer them when obvious. Ask only when the rewrite would otherwise be risky.
2. Rewrite the whole passage instead of performing only word-level substitutions.
3. Remove AI markers first: inflated praise, canned evaluation phrases, stacked katakana, vague attribution, label-colon bullets, over-structured headings, uniform sentence endings, and template openings or closings.
4. Replace deleted patterns with concrete facts already present in the source, a direct opinion, a small personal angle, shorter wording, or a cleaner sentence break.
5. Keep claims honest. Do not invent numbers, sources, anecdotes, or certainty just to make the text sound human.
6. Vary rhythm. Mix short and long sentences. In `です・ます` prose, allow occasional fragments or firmer endings when they fit the voice.
7. Run the final audit in [ai-patterns-ja.md](references/ai-patterns-ja.md). If the rewrite still feels AI-written, rewrite again.

## Rewrite Priorities

- Prefer concrete nouns and verbs over abstract evaluation.
- Prefer Japanese words over stacked katakana when the meaning stays clear.
- Drop empty transitions when sentence order already carries the logic.
- Remove commentary that tells the reader what is important.
- End with a real opinion, next action, or brief aftertaste instead of a template conclusion.

## Output

- Return the revised Japanese text first unless the user asks for diagnosis instead of a rewrite.
- Keep the explanation brief unless the user asks for rationale.
- When the user asks for diagnosis, list the remaining AI patterns by category and then provide a rewrite.

## Reference

Use [ai-patterns-ja.md](references/ai-patterns-ja.md) for the full 20-pattern checklist, examples, and the final self-audit.
