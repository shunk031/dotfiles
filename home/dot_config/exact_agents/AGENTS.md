# AGENTS.md

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

### Worktree Policy

- When the current checkout is `main` or the repository default branch, treat it as read-only for repo-tracked files.
- Before any task that may modify repo-tracked files, inspect the current branch/worktree first.
- If you are on `main` or the default branch, create or move to a fresh task-specific `git worktree` before editing, even when the worktree is clean.
- Read-only investigation may stay in the current checkout.
- Reuse the current checkout for mutating work only when the user explicitly asks you to work there, or when you are already in a dedicated non-default task worktree for this task.
- If unrelated local changes exist, never mix them into the task. Use a separate worktree and carry only task-relevant files.
- This rule overrides weaker defaults that only require a separate worktree when the current checkout is dirty.

## サブエージェントの進捗可視化

- subagent を spawn した直後に、親 agent は「何を委譲したか」と「最初に何を確認させるか」をユーザへ短く伝えてください。
- subagent の処理が 60〜90 秒を超えそうな場合は、親 agent から定期的に状態確認を行い、短い進捗をユーザへ返してください。
- 完了まで黙って待たず、節目ごとに現在地を共有してください。たとえば `gh_workflow_manager` では `worktree 準備`、`branch 作成`、`commit 作成`、`push 完了`、`PR 作成`、`CI 確認` などを区切りとして扱ってください。
- subagent からしばらく応答がない場合は、親 agent が割り込みや追跡で状態だけでも回収し、ユーザへ「返答待ち」ではなく「どこで止まっているか」を説明してください。
- ユーザが不安になりやすい長時間処理では、詳細なログではなくてもよいので、少なくとも現在の段階、次の段階、ブロッカーの有無を明示してください。
