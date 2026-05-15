## Codex Only

一旦 `~/.agents/AGENTS.md` を読んでください。

### Response Rule

- 必須応答: After reading this user-level `AGENTS.md`, say: `🤖 I read the user-level AGENTS.md.`

### Worklog のサブエージェント

- 担当: worklog の管理は custom subagent `worklog_manager` が担当します。`~/.codex/agents` 経由で利用できます。
- 起動条件: 実装、調査、レビューなど、軽微ではないタスクでは、セッションの早い段階で `worklog_manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時入力: 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。
- 委譲範囲: `.agents/worklog/codex/**` 配下の読み書きは、すべて `worklog_manager` に委譲してください。
- 直接更新禁止: main Codex agent から `.agents/worklog/codex/**` を直接更新しないでください。
- 事前確認: 本体の作業を進める前に、`worklog_manager` が返す learn の要約を確認してください。
- 失敗時: `worklog_manager` が必要な learn を読めない、または起動後に worklog を更新できない場合は、直接編集へフォールバックせず、その時点で失敗として扱って報告してください。

### GitHub / PR のサブエージェント

- 担当: GitHub / PR workflow は custom subagent `gh_workflow_manager` が担当します。`~/.codex/agents` 経由で利用できます。
- 起動条件: issue / PR の調査、branch / commit / push、pull request の作成・更新、CI 確認に入る前に、`gh_workflow_manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時入力: 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。dirty な作業ツリーから差分を切り出す場合は、対象ファイル一覧も明示してください。
- 直接実行禁止: GitHub 向けの `gh` 操作と `git` の write operation は、main Codex agent から直接実行しないでください。
- 橋渡し: worklog の記録が必要な場合は、`worklog_manager` との橋渡しを parent agent が担当してください。
- 失敗時: repo / worktree の検証、`gh` の利用、push、PR 更新、CI 確認のいずれかで失敗した場合は、親へフォールバックせず、そのまま失敗として扱って報告してください。

### セッション終了時のまとめ

- 出力条件: 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、`worklog_manager` から要約案を受け取り、以下の形式で 1 行のまとめを出力してください。
- 出力形式: `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`
