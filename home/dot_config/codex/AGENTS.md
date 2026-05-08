# AGENTS.md

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

## サブエージェントの進捗可視化

- subagent を spawn した直後に、親 agent は「何を委譲したか」と「最初に何を確認させるか」をユーザへ短く伝えてください。
- subagent の処理が 60〜90 秒を超えそうな場合は、親 agent から定期的に状態確認を行い、短い進捗をユーザへ返してください。
- 完了まで黙って待たず、節目ごとに現在地を共有してください。たとえば `gh_workflow_manager` では `worktree 準備`、`branch 作成`、`commit 作成`、`push 完了`、`PR 作成`、`CI 確認` などを区切りとして扱ってください。
- subagent からしばらく応答がない場合は、親 agent が割り込みや追跡で状態だけでも回収し、ユーザへ「返答待ち」ではなく「どこで止まっているか」を説明してください。
- ユーザが不安になりやすい長時間処理では、詳細なログではなくてもよいので、少なくとも現在の段階、次の段階、ブロッカーの有無を明示してください。

## Codex Only

### Response Rule

- After reading this user-level `AGENTS.md`, say: `🤖 I read the user-level AGENTS.md.`

### Worklog のサブエージェント

- worklog の管理は custom subagent `worklog_manager` が担当します。`~/.codex/agents` 経由で利用できます。
- 実装、調査、レビューなど、軽微ではないタスクでは、セッションの早い段階で `worklog_manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。
- `.agents/worklog/codex/**` 配下の読み書きは、すべて `worklog_manager` に委譲してください。
- main Codex agent から `.agents/worklog/codex/**` を直接更新しないでください。
- 本体の作業を進める前に、`worklog_manager` が返す learn の要約を確認してください。
- `worklog_manager` が必要な learn を読めない、または起動後に worklog を更新できない場合は、直接編集へフォールバックせず、その時点で失敗として扱って報告してください。

### GitHub / PR のサブエージェント

- GitHub / PR workflow は custom subagent `gh_workflow_manager` が担当します。`~/.codex/agents` 経由で利用できます。
- issue / PR の調査、branch / commit / push、pull request の作成・更新、CI 確認に入る前に、`gh_workflow_manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。dirty な作業ツリーから差分を切り出す場合は、対象ファイル一覧も明示してください。
- GitHub 向けの `gh` 操作と `git` の write operation は、main Codex agent から直接実行しないでください。
- worklog の記録が必要な場合は、`worklog_manager` との橋渡しを parent agent が担当してください。
- repo / worktree の検証、`gh` の利用、push、PR 更新、CI 確認のいずれかで失敗した場合は、親へフォールバックせず、そのまま失敗として扱って報告してください。

### セッション終了時のまとめ

- 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、`worklog_manager` から要約案を受け取り、以下の形式で 1 行のまとめを出力してください。
- `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`
