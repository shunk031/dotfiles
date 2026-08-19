---
name: shunk031-research-report-ja
description: Write or rewrite Japanese research reports, experiment notes, and published HTML reports for readers who did not follow the work, including experiment result reports and research-note documents. Use when a report must explain its question, measurement method, findings, and resulting decision to a first-time reader.
---

# How should a Japanese research report guide a first-time reader?

Use this skill for the full report, not only its prose polish. Treat each rule below as a hard requirement because an unclear report makes the reader reconstruct the study and can force a full rework cycle.

## What must the reader learn from the opening?

- Open with 3–5 plain-language lines answering, in order: what the work wanted to know, how it was measured, what was found, and what that determines. Reason: a first-time reader needs the study's purpose, evidence, finding, and consequence before seeing detail.
- Keep those four answers understandable without the rest of the report; use the opening as the reader's first screen. Reason: readers should be able to orient themselves without having followed the work.
- State the consequence, such as the chosen next action or unresolved decision, rather than stopping at a result. Reason: a result alone does not tell the reader what decision the evidence supports.

## How should sections and evidence be arranged?

- Make every section title a plain question that the section answers; avoid labels that merely name a topic. Reason: question headings tell readers what each section will resolve.
- Make the header or title state the tested question in plain words; never use internal codenames or process labels such as chain indices（段1、rung N）or execution labels（model-free、CPU、offline）as reader-facing identifiers or header content. Reason: internal labels make a report depend on context the reader does not have.
- For published HTML, make the header's main title one plain-language question and put answer cards immediately after it; each card pairs a relevant number with one plain sentence explaining what that number means. Reason: the first screen should expose the decision-relevant answers instead of making readers search for them.
- Put each case's evidence beside a one-line plain-language caption explaining why that case succeeded or failed; when the source gives no reason, say that the reason is not recorded instead of inventing one. Reason: a caption connects the observed case to its interpretation without requiring a separate legend.
- End published HTML with an honest scope note stating the exact cases or denominator covered and what the result cannot be generalized to. Reason: a bounded result must not be mistaken for a claim about unmeasured cases.
- If chain context is needed, explain it in one plain sentence in the body instead of exposing its internal label. Reason: readers need the relationship, not the process's private naming scheme.
- Keep the main path focused on the question, method, result, and consequence so a reader can stop after the opening and still understand the outcome. Reason: supporting detail should deepen comprehension without hiding the decision.

## Where should pre-registration and technical minutiae go?

- Move pre-registration and load-bearing minutiae—thresholds, parameter grids, tie-break rules, and band definitions—into a collapsible details section outside the reader's main path. Reason: technical audit detail should remain available without delaying the reader's understanding of the result.
- Keep the main text explicit about the resulting choice and its evidence; do not make the reader reconstruct it from hidden details. Reason: collapsed material may support a conclusion but must not be the only place where the conclusion can be found.

```html
<details>
<summary>どの条件を事前に固定したか</summary>

閾値、探索格子、同率時の決め方、判定帯の定義。
</details>
```

## Which words and numbers may remain in Japanese prose?

- Write concept words in Japanese; never leave English concept nouns inline in a Japanese sentence as Japanese–English pidgin. Reason: Japanese concept words let readers understand the claim without translating a mixed vocabulary.
- Keep English or romaji only for a literal code identifier, and pair it with its Japanese meaning at first use, such as `temperature`（温度を指定する設定名）. Reason: an identifier may need exact reproduction, but its role still needs to be readable to a Japanese audience.
- Never invent shorthand labels that the source does not define; replace them with the source's plain referent or ask for clarification. Reason: an invented label can silently change which case, condition, or result a claim refers to.
- Name what every number counts, such as `24件の評価対象` or `12回の再実行`; if the source does not establish the unit, preserve that uncertainty and ask instead of guessing. Reason: a number without its counted object cannot be checked or interpreted.
- Define every term at first use, or use a plain referent that a first-time reader can understand. Reason: an undefined term makes later evidence inaccessible to readers outside the original context.
- Keep reader-facing documents free of process metadata addressed to auditors: omit audit-compliance statements, repository mechanics such as gitignore status or file-path management, “frozen run” compliance talk, and instructions to auditors or orchestrators. Put compliance evidence in the PR body; keep the document to the question, method, results, meaning, and honest scope. Reason: process-facing status distracts readers from the scientific claim and does not explain its evidence.

## How should bullets and lines be formatted?

- When a topic has supporting evidence or conditions, make a parent bullet state the topic and nest those supports beneath it; write compact supporting bullets in noun-ending form（体言止め）and gloss every term at first use. Reason: nesting shows which evidence supports which topic while 体言止め keeps compact supports scannable.

```markdown
- ケースごとの判定
  - 事例Aの理由: 原稿に記載なし
  - 事例Bの理由: 原稿に記載なし
```

- Keep one logical line per sentence or bullet; do not insert a hard wrap in the middle of a sentence. Reason: a hard-wrapped sentence is easy to mistake for separate evidence or a separate instruction.
- Name a published-URL file with a hyphenated `YYYYMMDD-slug` form before its extension, for example `YYYYMMDD-ablation-result.html`. Reason: a date and readable slug make the published artifact identifiable without an internal process label.

## What must be checked before review?

Before review, actually read only the top screen as a first-time researcher: can that reader understand the question, method, result, and consequence from it alone? If not, revise the opening before requesting review. Reason: this final self-check tests the report from the intended reader's starting point rather than from the author's memory.
