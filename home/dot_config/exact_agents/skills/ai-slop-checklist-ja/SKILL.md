---
name: ai-slop-checklist-ja
description: AI臭い日本語をレビューし、書き手の不在、主体の弱さ、構造テンプレ、抽象語、翻訳調、表層記号をチェックして修正案まで出すスキル。ブログ記事、技術記事、note/Zenn草稿、SNS投稿、メール、README、発表原稿などの日本語を、AIっぽさの診断、採点、具体的な直し方、軽いリライト案まで含めて確認したいときに使う。
---

# AI Slop Checklist JA

## Read Acknowledgement

- After reading this skill, say: `🧾 私は ai-slop-checklist-ja を読みました。`

## Overview

Use this skill to review Japanese prose for AI-like writing before rewriting it.
Treat the core problem as the absence of a writer, not as a surface issue such as punctuation or emoji.

For detailed criteria, read [checklist.md](references/checklist.md) before reviewing user text.

## Workflow

1. Infer the text's purpose, audience, and expected writer position from context.
2. Read [checklist.md](references/checklist.md).
3. Review in this order: position, agency, structure, vocabulary, rhythm, then symbols.
4. Score the draft on the five axes in `checklist.md` unless the user asks for a lighter pass.
5. Return findings in order of impact, then include a concrete fix or short rewrite.

## Output Shape

Use this structure by default:

```markdown
## 判定
- 総評: ...
- 書き直し推奨: はい/いいえ
- スコア: ../50

## 重大な順の指摘
- 問題箇所: ...
  理由: ...
  直し方: ...

## チェックリスト
- [ ] 立場
- [ ] 主体
- [ ] 構造
- [ ] 語彙
- [ ] リズム
- [ ] 記号

## 修正案
...
```

For very short text, compress the output but keep `判定`, top findings, and `修正案`.

## Guardrails

- Do not fabricate personal experiences, numbers, named entities, failures, preferences, or emotions.
- If the draft lacks the writer's position, say what material is missing before rewriting.
- Preserve facts, intent, and necessary politeness.
- Do not make text deliberately sloppy just to look human.
- Do not overfit to surface markers. Fix dashes, quotes, emoji, and markdown remnants after fixing position and agency.
