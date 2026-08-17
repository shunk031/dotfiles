---
name: shunk031-structured-writing
description: Structure and revise detailed instructions, plans, reports, documentation, evidence documents such as TRAINING.md, repository protocol documents, pull-request bodies, and bullet lists so their hierarchy and relationships are clear. Use when drafting or reorganizing multi-part prose and repository completion or status reports, even when the resulting report should be concise, especially when deciding between headings, topic bullets, supporting nested bullets, and independent flat items. Do not use for ordinary conversational short answers, code-only output, or machine-readable data unless the user also requests prose organization.
---

# Structured Writing

Make the document's logical relationships visible without imposing a template on every sentence.

## Structure

- Keep reports and responses concise. Expand only when asked.
- Lead a detailed section with its main conclusion or topic.
- Use headings to separate distinct concerns, not to decorate short text. For short repository completion or status reports, lead with the outcome and essential validation in the smallest readable paragraph or compact list; omit template headings or sections when that is enough, while retaining headings for genuinely distinct concerns in detailed reports.
- Use `Label: Details` when it improves scanning. Treat it as an option, not a mandatory template.
- Write procedures as steps to perform when work begins and in the order that prevents problems, rather than as checks to make only after a problem occurs. For example, when introducing a hook, write “When starting work in a new clone or worktree, install the hook before editing or committing,” rather than “Check it if it does not run.”
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
- In reader-facing evidence or protocol documents, use a conceptual heading and the reader's outcome first. Do not use a bare issue number (for example, `# 271`) as a heading or as the grammatical subject; mention the issue as supporting metadata after the rule or result.

### Japanese technical reports

- When a Japanese report has one topic followed by facts that explain or qualify it, make the topic the parent bullet and nest the supporting facts below it. Do not put several related full sentences into one flat bullet.
- End supporting bullets with a noun phrase (体言止め) when they function as compact evidence or conditions. Keep the parent as the readable topic; do not force every bullet into the same sentence ending.
- Keep the concrete subject and the exact unit in the topic or its first supporting bullet. Do not invent a shorter label while compressing the source.

  ```text
  Before
  - モデルはQwen3-VL-32B-ThinkingをSGLang経由で呼び出した。サンプリングはtemperature=0、thinking有効、画像番号付与とし、座標はPicture 1基準の0..1000に正規化した。主実行は max_tokens=4096 とした。全24行のうち、reasoningが4096-token上限まで消費されてfinalが空になった12行だけ、入力とpromptを変えず max_tokens=8192 で再実行した。retryは別のサンプルではなく、同じ入力・promptに対して長さ上限だけを変えた再実行である。

  After
  - モデルはQwen3-VL-32B-ThinkingをSGLang経由で呼び出し
    - サンプリングは`temperature=0`、thinking有効（`enable_thinking=true`）、画像番号付与（`add_vision_id=true`）とし、座標はPicture 1基準の `0..1000` に正規化
  - 初回実行は`max_tokens=4096`
    - 24クエリ（3実験 × 8ペア）のうち、reasoningが4096-token上限まで消費されて最終回答が空になった12クエリだけ、入力とpromptを変えず`max_tokens=8192`で再実行
  ```

- In the example, `24クエリ` names what is counted and `最終回答` names the reader-facing result. Apply the same rule to every report: if a term or unit is not already clear, define it at first use or write the plain referent instead of copying an opaque shorthand.

- Treat the Japanese example as a required final check, not as optional style advice. Before returning the rewrite, verify all of the following:
  - A parent bullet names the topic (`モデルは…` or `初回実行は…`); related settings, conditions, and retry facts are nested below that parent.
  - Supporting bullets end in compact noun phrases (体言止め) where they are evidence or conditions; parent bullets remain readable topics.
  - Never introduce or preserve an unexplained compression label. In this incident, `主実行` becomes `初回実行`, `final` becomes `最終回答`, and `retry` becomes `再実行`.
  - Replace `全24行` with the supplied counted object, such as `24クエリ（3実験 × 8ペア）`, only when the source establishes that object. If the source does not establish what is counted, flag the missing unit instead of guessing.

## Plans

- Make implementation plans decision-complete: name directories and file paths; functions, classes, types, configuration keys, CLI arguments, and public APIs to add, edit, or delete; per-file behavior and removal targets; test files, cases, and essential assertions; assumptions, defaults, and unresolved questions. Put the complete plan in the response; do not substitute a link, summary, or reference to another artifact.
- For important or complex changes, include the proposed function signature, pseudocode, or a roughly 5–20 line code fragment and explain data flow, state, asynchrony, migration, or parallelization decisions that an implementer must not guess. For concurrency or other runtime-sensitive changes, choose and state the execution model, ordering, cancellation or partial-result policy, and failure behavior rather than leaving those decisions unresolved.
- Keep the prose and proposed code consistent: implement each claimed behavior in the fragment or assign it explicitly to a named function or follow-up step. If a plan claims bounded or incremental scheduling or fail-fast behavior, its pseudocode must limit in-flight submissions and stop or cancel pending work consistently rather than enqueueing all inputs upfront.
- Resolve discoverable repository facts before planning. Ask only for product intent or decisions that cannot be derived safely.
- When a non-product implementation detail cannot be discovered, choose and state a reasonable default plus the assumption that supports it; do not leave the choice to the implementer.
- Do not present an incomplete plan as final; describe each file or subsystem precisely enough that implementation can start without another design pass. For example, identify a function such as `build_dataset()` and state how data flow changes, then name the corresponding equivalence test.
- When proceeding on assumptions, state them under `Assumptions` or `Premises` and explain their implementation effect.

## Revision

1. Identify the intended audience, outcome, and independent topics.
2. Group supporting details under the topic they explain.
3. Remove repeated framing, placeholder headings, and conclusions that merely restate the list.
4. Preserve exact commands, paths, identifiers, constraints, and authorization language.
5. Read the result linearly and confirm that each level remains understandable without relying on formatting alone.
