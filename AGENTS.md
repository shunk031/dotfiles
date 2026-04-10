# AGENTS.md

## 応答ルール

- この `AGENTS.md` を読んだら「🤖 私は shunk031/dotfiles 向け AGENTS.md を読みました。」と言ってください。

## 共通ルール

- 共通の Codex ルールは `home/dot_config/codex/AGENTS.md` を読んで従ってください。
- このファイルには repo 固有の追記事項だけを書き、`home/dot_config/codex/AGENTS.md` と重複する内容は書かないでください。

## Git / PR 運用

- branch / commit / pull request 作成を依頼され、現在の作業ツリーに関係ない staged / unstaged / untracked 変更がある場合は、既定ブランチ基点の別 `git worktree` を優先して作成してください。
- 別 `git worktree` には今回の作業対象だけを反映し、関係ない変更を branch や pull request に混ぜないでください。
- ユーザーが明示的に現在の branch / worktree での作業を求めた場合のみ、その指示を優先してください。

## テスト方針

- `bats` によるテストはローカルでは実行しないでください。
- `bats` の結果確認が必要な場合は GitHub へ push して GitHub Actions の CI を起動し、その実行結果を確認してください。
