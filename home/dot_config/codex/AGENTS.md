# AGENTS.md

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

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

### セッション終了時のまとめ

- 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、`worklog_manager` から要約案を受け取り、以下の形式で 1 行のまとめを出力してください。
- `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`
