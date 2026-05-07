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

### Worklog Subagent

- Worklog management is handled by the custom subagent `worklog_manager`, exposed through `~/.codex/agents`.
- For every non-trivial task, spawn `worklog_manager` once near the start of the session and reuse the same thread for the rest of the task.
- Pass the task summary, the initial user prompt, and a `parent_owner` value such as `codex-foo`.
- Delegate all reads and writes under `.agents/worklog/codex/**` to `worklog_manager`.
- Do not update `.agents/worklog/codex/**` directly from the main Codex agent.
- Use the learn summary returned by `worklog_manager` before continuing the main task.
- If `worklog_manager` cannot read the required learn files or cannot update the worklog after it starts, fail hard and report the problem instead of falling back to direct edits.

### セッション終了時のまとめ

- 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、`worklog_manager` から summary 案を受け取り、以下の形式で 1 行のまとめを出力してください。
- `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`
