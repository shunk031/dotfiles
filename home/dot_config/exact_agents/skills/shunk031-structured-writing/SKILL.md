---
name: shunk031-structured-writing
description: Structure and revise detailed instructions, plans, reports, documentation, and bullet lists so their hierarchy and relationships are clear. Use when drafting or reorganizing multi-part prose, especially when deciding between headings, topic bullets, supporting nested bullets, and independent flat items. Do not use for short answers, code-only output, or machine-readable data unless the user also requests prose organization.
---

# Structured Writing

Make the document's logical relationships visible without imposing a template on every sentence.

## Structure

- Lead a detailed section with its main conclusion or topic.
- Use headings to separate distinct concerns, not to decorate short text.
- Use `Label: Details` when it improves scanning. Treat it as an option, not a mandatory template.
- Write procedures as steps to perform when work begins and in the order that prevents problems. For example, write “In a new clone or worktree, install the hook before editing or committing,” not “Check the hook if it does not run.”
- When one bullet states a topic and later bullets only support it, make the parent the topic sentence, nest supporting sentences, and use the last child as a conclusion when useful.

  ```text
  - topic sentence
    - support sentence
    - support sentence
    - conclusion sentence
  ```

- Treat consecutive sentences beginning with a pronoun such as “it” as supporting details when they refer to the preceding topic; keep a sentence with a different subject as an independent item.
- Group every claim that explains the same topic under that parent, including scope, caching, and failure behavior; do not detach one merely because it describes a different aspect.
- Do not leave supporting sentences in a flat list without a topic sentence. Keep bullets at one level only when each item can stand on its own as a topic sentence.
- Convert procedures into ordered steps when sequence matters; keep unordered lists for independent points.

## Plans

- Make implementation plans decision-complete: name directories and file paths; functions, classes, types, configuration keys, CLI arguments, and public APIs to add, edit, or delete; per-file behavior and removal targets; test files, cases, and essential assertions; assumptions, defaults, and unresolved questions.
- For important or complex changes, include the proposed function signature, pseudocode, or a roughly 5–20 line code fragment and explain data flow, state, asynchrony, migration, or parallelization decisions that an implementer must not guess.
- Keep the prose and proposed code consistent: implement each claimed behavior in the fragment or assign it explicitly to a named function or follow-up step.
- Resolve discoverable repository facts before planning. Ask only for product intent or decisions that cannot be derived safely.
- When a non-product implementation detail cannot be discovered, choose and state a reasonable default plus the assumption that supports it; do not leave the choice to the implementer.
- Do not present an incomplete plan as final; describe each file or subsystem precisely enough that implementation can start without another design pass. For example, identify a function such as `build_dataset()` and state how its processing changes, then name the corresponding equivalence test.
- When proceeding on assumptions, state them under `Assumptions` or `Premises` and explain their implementation effect.

## Revision

1. Identify the intended audience, outcome, and independent topics.
2. Group supporting details under the topic they explain.
3. Remove repeated framing, placeholder headings, and conclusions that merely restate the list.
4. Preserve exact commands, paths, identifiers, constraints, and authorization language.
5. Read the result linearly and confirm that each level remains understandable without relying on formatting alone.
