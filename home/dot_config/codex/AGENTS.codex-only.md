# AGENTS.codex-only.md

> [!NOTE]
> After reading this `AGENTS.codex-only.md`, say: `🤖 I read ~/.codex/AGENTS.codex-only.md.`

`~/.codex/AGENTS.md` から追加で読む Codex 固有の設定です。

### Plan の具体性 (Codex 固有)

- 共通ルール: plan の具体性の共通ルールは `~/.agents/AGENTS.md` の「Plan の具体性」を適用してください。
- 未完成条件: 共通ルールの必須項目が欠けている plan は未完成として扱い、未完成の状態で `<proposed_plan>` を出してはいけません。

### サブエージェントの進捗可視化

- 委譲直後: subagent を spawn した直後に、親 agent は「何を委譲したか」と「最初に何を確認させるか」をユーザへ短く伝えてください。
- 定期確認: subagent の処理が長引く場合、特に `gh-workflow-manager` と `worklog-manager` では 180 秒を超えて待たず、親 agent が `wait_agent(timeout_ms=180000)` を上限に状態確認を行い、短い進捗をユーザへ返してください。
- 節目共有: 完了まで黙って待たず、節目ごとに現在地を共有してください。たとえば `gh-workflow-manager` では `worktree 準備`、`branch 作成`、`commit 作成`、`push 完了`、`PR 作成`、`CI 確認` を区切りとし、`worklog-manager` でも `learn 読み込み完了`、`plan 更新`、`todo 更新`、`close-out 要約準備` など返せる節目を共有してください。
- 完了条件: `gh-workflow-manager` に PR 作成・更新を委譲した場合、親 agent は PR URL を受け取った時点で完了扱いにしてはいけません。少なくとも `CI 確認` まで進み、required checks の結果が確定してからユーザへ最終報告してください。
- 停滞時: 180 秒待っても完了しない、または進捗が見えない場合は、親 agent が同じ subagent スレッドへ `send_input` で追加の状態確認を送り、少なくとも `現在の段階`、`次の段階`、`ブロッカーの有無` を回収してユーザへ説明してください。
- 停滞時の再確認: 状態確認を送った後は、再び 180 秒待たず、まず 60 秒だけ待ってください。60 秒で応答がなければ停滞として扱い、完了済みでない限り、その subagent を閉じて再起動してください。
- 停滞時の報告: timeout 後に追加で待つ場合は、ユーザへ「問い合わせ済み」「再起動する」「まだ待つ」のどれかを短く報告してください。黙って次の長い待機に入らないでください。
- 長時間処理: ユーザが不安になりやすい長時間処理では、詳細なログではなくてもよいので、少なくとも現在の段階、次の段階、ブロッカーの有無を明示してください。
- 追跡方法: 状態確認はまず非割り込みで行い、`interrupt=true` は明らかな停止や即時の方針変更が必要な場合だけ使ってください。

### Worklog のサブエージェント

- 担当: worklog の管理は custom subagent `worklog-manager` が担当します。`~/.codex/agents` 経由で利用できます。
- 起動条件: 実装、調査、レビューなど、軽微ではないタスクでは、セッションの早い段階で `worklog-manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時入力: 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。
- 委譲範囲: `.agents/worklog/codex/**` 配下の読み書きは、すべて `worklog-manager` に委譲してください。
- 直接更新禁止: main Codex agent から `.agents/worklog/codex/**` を直接更新しないでください。
- 事前確認: 本体の作業を進める前に、`worklog-manager` が返す learn の要約を確認してください。
- 失敗時: `worklog-manager` が必要な learn を読めない、または起動後に worklog を更新できない場合は、直接編集へフォールバックせず、その時点で失敗として扱って報告してください。

### GitHub / PR のサブエージェント

- 担当: GitHub / PR workflow は custom subagent `gh-workflow-manager` が担当します。`~/.codex/agents` 経由で利用できます。
- 起動条件: issue / PR の調査、branch / commit / push、pull request の作成・更新、CI 確認に入る前に、`gh-workflow-manager` を 1 回だけ spawn し、その後は同じスレッドを使い続けてください。
- 起動時入力: 起動時には、タスクの要約、最初のユーザープロンプト、`codex-foo` のような `parent_owner` を渡してください。dirty な作業ツリーから差分を切り出す場合は、対象ファイル一覧も明示してください。
- 直接実行禁止: GitHub 向けの `gh` 操作と `git` の write operation は、main Codex agent から直接実行しないでください。
- 橋渡し: worklog の記録が必要な場合は、`worklog-manager` との橋渡しを parent agent が担当してください。
- 失敗時: repo / worktree の検証、`gh` の利用、push、PR 更新、CI 確認のいずれかで失敗した場合は、親へフォールバックせず、そのまま失敗として扱って報告してください。

### セッション終了時のまとめ

- 出力条件: 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、`worklog-manager` から要約案を受け取り、以下の形式で 1 行のまとめを出力してください。
- 出力形式: `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`
