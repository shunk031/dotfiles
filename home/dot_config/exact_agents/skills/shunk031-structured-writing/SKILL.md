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
- In reader-facing evidence or protocol documents, use a conceptual heading and the reader's outcome first. Do not use a bare identifier as a heading or as the grammatical subject; mention metadata after the rule or result.

### Japanese technical reports

- When a Japanese report has one topic followed by facts that explain or qualify it, make the topic the parent bullet and nest the supporting facts below it. Write the parent as a reader-facing statement, not as an unexplained `label: value` pair, and do not put several related full sentences into one flat bullet.
- End supporting bullets with a noun phrase (体言止め) when they function as compact evidence or conditions. Keep the parent as the readable topic; do not force every bullet into the same sentence ending.
- 書き換えを返す前に、次の3段階を完了するまで最終稿を返さない。
  1. 原文が定義していない、または役割を説明していないラベル・単位・略語をすべて列挙する。
  2. 列挙した各項目を平易な参照先に置き換えるか、初出で定義する。原文に読み手向けの意味がない項目は、意味を推測できても未定義として指摘し、補わない。
  3. すべての数値について数える対象を確認し、単位の初出でその対象を明記する。

  ```text
  Before
  - 負荷試験は同時接続100で実施した。全500リクエストのうち、応答が5秒を超えた12リクエストだけ、内容を変えずタイムアウト上限10秒で再送した。

  After
  - 負荷試験は同時接続100で実施
    - 対象は全500リクエスト
  - 応答5秒超の12リクエストだけ再送
    - 内容は同一、タイムアウト上限のみ10秒に変更
  ```

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
4. Preserve exact commands, paths, canonical identifiers, constraints, and authorization language; do not mistake an undefined prose label for a canonical identifier.
5. Read the result linearly and confirm that each level remains understandable without relying on formatting alone.
