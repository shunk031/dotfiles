---
name: shunk031-doc-slop-review
description: Review reader-facing text with the repository's two-tier slop review before publishing it. Use when writing or editing documentation, README or TRAINING files, issue bodies and comments, pull request bodies and descriptions, or status reports that another person will read. Runs deterministic checks and one blind model judge over the draft, quotes each problem, and produces a PASS or FAIL to attach to the publish report; an unavailable review is a failed gate, not a PASS.
---

# Document Slop Review

## 読了時の応答

- この skill を読んだら、`🧹 私は shunk031-doc-slop-review を読みました。` と応答する。

## The command

Run `scripts/doc_slop_review.py` from the dotfiles repository checkout:

```bash
cd "$(chezmoi source-path)"   # typically ~/.local/share/chezmoi
uv run --python 3.14.6 --no-project python scripts/doc_slop_review.py DRAFT.md
```

Give this command to the user when you report the work. Do not paraphrase it
and do not ask the reader to reconstruct it from a description.

## When to use

Run this before publishing any text a person will read: repository
documentation, `README.md` and `TRAINING.md` style files, issue bodies and
comments, pull request bodies, and status or completion reports.

Skip it for code-only changes, machine-readable data, and ordinary
conversational replies. A commit message body is optional; review it when it
carries the explanation a reader depends on.

## Flow

1. Write the draft to a file, or pipe it in. Do not publish first and review
   after.
2. Run the review on the draft with the command above.
3. Address every finding, or state why a finding does not apply. A finding you
   disagree with is answered in the report, not ignored silently.
4. Re-run until the complete two-tier review reports PASS, then attach that
   verdict to the publish report. A deterministic-only PASS (including
   `--skip-model`) is not a complete review and is not permission to publish.
5. Treat exit code `2` as a failed review that blocks publication. This includes
   a model-judge timeout, an unavailable judge, an invalid judge response, or a
   missing reviewable draft. Stop and report the failure instead of publishing.
   Retry only when the review can be run again; two timeouts do not become a
   PASS.
6. Publish after a PASS, or only after an explicit user waiver. A waiver for a
   FAIL or an unavailable review must name the failed gate and record the user's
   reason in the same publish report; the worker must not infer or silently grant
   the waiver.

## Where the script lives

The script is `scripts/doc_slop_review.py` in the dotfiles **repository
checkout**, not in this applied skill tree. It imports the repository's
`scripts/agent_guidance_eval.py` for its Codex conventions, so it only runs
from that checkout. That is why the command changes directory first.

## More command shapes

Review a pull request body before creating or editing it:

```bash
gh pr view 123 --json body --jq .body | \
  uv run --python 3.14.6 --no-project python scripts/doc_slop_review.py
```

Review only the prose a change adds:

```bash
git diff -- '*.md' | \
  uv run --python 3.14.6 --no-project python scripts/doc_slop_review.py --diff
```

Useful flags: `--json` for machine-readable output, `--skip-model` for the
deterministic tier alone when no model call is available. On a host without
unprivileged user namespaces, export
`AGENT_GUIDANCE_EVAL_SANDBOX=danger-full-access` first.

Exit codes are `0` for PASS, `1` for FAIL, and `2` when the review could not
run. A `2` is not a PASS; report it as a failed review.

## Reading the output

Each finding names its rubric category, quotes the offending text, explains the
problem, and proposes a fix. Findings marked `regex` come from the
deterministic tier; findings marked `model` come from the judge.

- A clean deterministic tier does not prove that every technical term,
  abbreviation, or unit is defined. Regex cannot know whether `24行` means
  lines, queries, or records, or whether `final` has been introduced. Manually
  inspect terminology and reader context even when the deterministic tier
  reports no findings; the Japanese vocabulary owner is
  `shunk031-ai-slop-checklist-ja`.

A model finding is discarded when its quoted excerpt does not appear in the
document, which keeps the output specific. The report counts those in
`discarded_model_findings`; a nonzero count means the judge saw something it
could not quote, so read the draft again rather than treating it as noise.

## Related skills

- `shunk031-ai-slop-checklist-ja` owns the Japanese review criteria and the
  five-axis scoring. The rubric this script uses is derived from it; consult
  that skill for the detailed criteria and for manual Japanese review.
- `shunk031-structured-writing` owns how to compose and organize the text.
  Use it while drafting; use this skill to check the draft before publishing.
- `shunk031-humanizer-ja` owns rewriting Japanese prose once a problem is found.
