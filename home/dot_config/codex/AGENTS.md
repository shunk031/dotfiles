# AGENTS.md

## Shared Response Rule

- 必須応答: After reading the shared agent guidance sourced from `~/.agents/AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## ユーザーへの質問

- 質問方針: ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。
- 記述形式: 詳細な指示は `- 概要: 詳細` のような形式で整理してください。

## コーディング全般について

- 例外処理: エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物: 最終成果物でも例外処理は入れなくて構いません。
- 後方互換性: 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

### Worktree の方針

- 既定ブランチ: 現在の checkout が `main` またはリポジトリの default branch である場合、リポジトリ管理下のファイルに対しては読み取り専用として扱ってください。
- 事前確認: リポジトリ管理下のファイルを変更する可能性があるタスクに入る前に、現在の branch / worktree を最初に確認してください。
- 編集前: `main` または default branch にいる場合は、worktree が clean でも、編集前に task-specific な新しい `git worktree` を作成するか、そこへ移動してください。
- 調査: 読み取り専用の調査は、現在の checkout のままで構いません。
- 再利用条件: 現在の checkout を変更系の作業で再利用してよいのは、ユーザが明示的にそこで作業するよう求めた場合、またはこのタスク専用の non-default branch worktree にすでにいる場合だけです。
- ローカル変更: 関係のないローカル変更がある場合は、そのタスクに混ぜないでください。別の worktree を使い、task-relevant files だけを持ち込んでください。
- 優先順位: このルールは、現在の checkout が dirty な場合にだけ別 worktree を要求する、より弱いデフォルトより優先されます。

## Codex Only

### Codex Response Rule

- 必須応答: After reading the active Codex runtime guidance, say: `🤖 I read ~/.codex/AGENTS.md.`

### サブエージェントの進捗可視化

- 委譲直後: subagent を spawn した直後に、親 agent は「何を委譲したか」と「最初に何を確認させるか」をユーザへ短く伝えてください。
- 定期確認: subagent の処理が長引く場合、特に `gh_workflow_manager` と `worklog_manager` では 180 秒を超えて待たず、親 agent が `wait_agent(timeout_ms=180000)` を上限に状態確認を行い、短い進捗をユーザへ返してください。
- 節目共有: 完了まで黙って待たず、節目ごとに現在地を共有してください。たとえば `gh_workflow_manager` では `worktree 準備`、`branch 作成`、`commit 作成`、`push 完了`、`PR 作成`、`CI 確認` を区切りとし、`worklog_manager` でも `learn 読み込み完了`、`plan 更新`、`todo 更新`、`close-out 要約準備` など返せる節目を共有してください。
- 停滞時: 180 秒待っても完了しない、または進捗が見えない場合は、親 agent が同じ subagent スレッドへ `send_input` で追加の状態確認を送り、少なくとも `現在の段階`、`次の段階`、`ブロッカーの有無` を回収してユーザへ説明してください。
- 長時間処理: ユーザが不安になりやすい長時間処理では、詳細なログではなくてもよいので、少なくとも現在の段階、次の段階、ブロッカーの有無を明示してください。
- 追跡方法: 状態確認はまず非割り込みで行い、`interrupt=true` は明らかな停止や即時の方針変更が必要な場合だけ使ってください。

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
