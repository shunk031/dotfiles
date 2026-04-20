# Humanizer JA Reference

Base this workflow on the original humanizer-ja spec, WikiProject AI Cleanup style observations, and Japanese-specific editing patterns.
Use this file when the rewrite needs the full rule set, concrete examples, or a final audit.

## Table of Contents

1. Guardrails
2. Category 1: Vocabulary and stock phrasing
3. Category 2: Structure and formatting
4. Category 3: Tone and sentence habits
5. Category 4: Japanese-specific patterns
6. Category 5: Self-audit
7. Add human voice
8. Quick checklist

## Guardrails

- Keep the original meaning, register, and factual scope unless the user asks for a stronger rewrite.
- Do not fabricate numbers, sources, personal episodes, named experts, or confidence.
- When the source lacks specifics, remove the empty emphasis and leave the sentence plain.
- When adding a personal angle, use one that is already supported by the user's viewpoint or surrounding context.
- Keep necessary technical terms when replacing them would reduce precision.

## Category 1: Vocabulary and stock phrasing

### 1. Stop overplaying significance

Replace exaggerated importance with an observed result.
If the source does not contain concrete evidence, remove the emphasis instead of inventing one.

NG:
`この取り組みは、業界全体のDX推進において極めて重要な役割を果たしており、その意義は計り知れない。`

Better:
`この取り組みで、社内の申請処理が3日から4時間に縮まった。`

### 2. Remove canned evaluation phrases

Treat the following phrases as rewrite targets because they often signal LLM output.

- `浮き彫りにしており`
- `今後の展開が注目されます`
- `多面的な`
- `包括的な`
- `画期的な`
- `注目に値する`
- `〜と言えるでしょう`
- `〜ではないでしょうか`
- `重要な示唆を与えている`

Rewrite rule:
- State what became visible instead of saying `浮き彫りにしており`.
- Delete `今後の展開が注目されます` or replace it with a concrete prediction.
- Explain what is actually broad, comprehensive, or groundbreaking.
- Replace `注目に値する` with one sentence explaining why you care.
- Turn `〜と言えるでしょう` and `〜ではないでしょうか` into direct statements.
- Spell out the specific implication instead of `重要な示唆を与えている`.

### 3. Reduce stacked katakana

Replace unnecessary loanwords with ordinary Japanese when meaning stays clear.
Treat three or more katakana business words in a row as a warning sign.

NG:
`ソリューションをレバレッジして、イノベーティブなアプローチでトランスフォーメーションを推進する。`

Better:
`既存の仕組みを活かして、新しいやり方で業務を変える。`

### 4. Fix vague attribution

Avoid anonymous authority such as `業界の専門家によると`, `調査結果が示すように`, or `多くの企業が指摘しているように`.

Rewrite rule:
- Name the exact source when it exists.
- When the source is unavailable, write it as your own view or state that no source is cited.

## Category 2: Structure and formatting

### 5. Remove bold-plus-colon bullets

The `**Label:** content` bullet pattern is a strong AI marker in Japanese and English.
Delete the label and keep only the content in natural wording.

NG:
- `**速度:** 処理速度が3倍に向上`
- `**安全性:** セキュリティ基準を満たす`
- `**コスト:** 月額費用を40%削減`

Better:
- `処理速度が3倍になった`
- `セキュリティ基準もクリアしてる`
- `月額費用は40%減`

### 6. Resist forced trios

Do not force every answer into three bullets, three steps, or three takeaways.
Write one item when one is enough, or four when four are real.
Treat `3つにまとめると` as a warning phrase that needs justification.

### 7. Replace em dashes

Replace `——` with parentheses, commas, or a sentence split.

NG:
`Claude Code——Anthropicが開発したCLIツール——を使えば`

Better:
`Claude Code（AnthropicのCLIツール）を使えば`

### 8. Reduce over-structured headings

Do not split a short passage into unnecessary `h2` or `h3` sections.
When a section is around 300 Japanese characters or shorter, prefer natural paragraph flow over heading scaffolding.

## Category 3: Tone and sentence habits

### 9. Delete preachy lead-ins

Cut prefaces such as:

- `ここで重要なのは〜という点です`
- `〜について理解しておく必要があります`
- `注意すべき点として`

Write the substance directly and let the reader judge what matters.

### 10. Thin out transitions

Watch for overused transitions such as:

- `一方で`
- `しかしながら`
- `加えて`
- `このように`
- `さらに`
- `とりわけ`

When three or more appear in a short span, remove at least half and rely on sentence order to carry the logic.

### 11. Break the denial contrast pattern

Treat repeated `〜ではない。〜だ。` constructions as an AI habit.
When the pattern appears more than once, rewrite at least one instance into a different structure.

NG:
`単なるツールではない。パラダイムシフトだ。`

NG:
`コストの問題ではない。文化の問題だ。`

### 12. Avoid pandering

Remove empty praise such as:

- `素晴らしいご質問ですね`
- `非常に良い指摘です`
- `おっしゃる通り`

If praise is necessary, say what is actually good instead of flattering the reader.

### 13. Remove AI-style significance tails

Delete add-on clauses that explain what the fact supposedly proves when the data can stand alone.

NG:
`売上は前年比120%でした。これは同社の戦略が功を奏していることを示しており、今後の成長が期待されます。`

Better:
`売上は前年比120%でした。`

Targets:
- `〜を示しており`
- `〜を物語っています`

## Category 4: Japanese-specific patterns

### 14. Break uniform politeness

Fully even `です・ます` endings read synthetic.
Mix in short noun phrases, clipped lines, or firmer endings when the tone allows it.

### 15. Drop repeated subjects

Japanese often omits the subject when context is clear.
Cut repeated subjects that are carried over from English thinking.

NG:
`このツールは高速です。このツールはセキュリティも強固です。このツールは無料で使えます。`

Better:
`高速で、セキュリティも強固。しかも無料。`

### 16. Shorten `〜することができます`

Replace `〜することができます` with a shorter form every time unless there is a specific legal or formal reason to keep it.

Examples:
- `設定を変更することができます` -> `設定を変更できます`
- Better when tone allows: `設定は変えられます`

### 17. Warm up the conclusion

Do not end with abstract, low-temperature conclusions such as:

- `以上のことから、AIツールの活用は今後ますます重要になると考えられます。`

Prefer a real opinion or felt takeaway.

Better:
`正直、もうAIなしで仕事するのは無理だと思ってます。`

## Category 5: Self-audit

### 18. Check the opening

Rewrite openings that start with:

- `ここでは〜について解説します`
- `〜が注目を集めています`
- `近年、〜が急速に進展しており`

Start from a concrete number, scene, event, or personal observation instead.

### 19. Check the ending

Rewrite endings that stop at:

- `今後の展開が注目されます`
- `〜が期待されます`
- `〜と言えるでしょう`

End with one of these instead:
- a direct opinion
- a specific next action
- a short line that leaves a real aftertaste

### 20. Run the double-check

Ask:

`この文章を読んで、AIが書いたと思うか？`

If the answer is yes, inspect these points again:

- Do stock evaluation phrases remain?
- Does any `**Label:** content` bullet remain?
- Is the tone too uniform from start to finish?
- Are concrete facts or grounded observations present where they should be?
- Does the conclusion contain a real human voice?

Rewrite again until the answer becomes no.

## Add Human Voice

After removing patterns, add a small amount of human presence so the text does not become empty.

### Add one grounded experience

Use forms such as:

- `自分の場合は〜`
- `うちでは〜`
- `実際に試したら〜`

Only add them when they are supported by context.

### Add one real opinion

Use forms such as:

- `正直、これは微妙だと思ってます`
- `個人的にはこっちの方がいい`

Keep it modest when the source does not justify a strong claim.

### Break the rhythm

Place a short sentence after a long one.
Allow an occasional fragment or noun-ending line.
Avoid perfectly even sentence length or perfectly even politeness.

### Admit incompleteness

Use limited uncertainty when it is true:

- `まだ試してない`
- `ここは自信ない`

Over-polished certainty often reads artificial.

## Quick Checklist

- `浮き彫りにしており` and `今後の展開が注目されます` are gone.
- No `**Label:** content` bullets remain.
- No `——` remains.
- `〜と言えるでしょう` and `〜ではないでしょうか` are gone.
- No `〜することができます` remains unless there is a clear reason.
- The opening and ending are not template sentences.
- At least one grounded opinion or experience is present when the tone allows it.
- A final read does not feel like AI wrote it.
