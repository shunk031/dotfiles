# AGENTS.md

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## セッション開始時の learn 確認

- 作業を開始する前に、`.agents/worklog/codex/learn/learn_index.md` を読み、過去のセッションで得た知見やエラーの教訓を把握してください。
- インデックスの中で今回のタスクに関連しそうな項目があれば、該当する learn ファイルの本文も読んでから作業に取り掛かってください。
- 特にエラーや失敗に関する教訓は、同じ過ちを繰り返さないように作業中も意識してください。

## セッション終了時のまとめ

- 会話の自然な区切りで、直ちに次のアクションが想定されない場合は、以下の形式で 1 行のまとめを出力してください。
- `📝 まとめ: <このセッションで完了した内容を 1〜2 文で要約してください。未完了のタスクや次のアクションがあれば末尾に追記してください。>`

## プロジェクトの構成について

- プロジェクト構成はプログラミング言語ごとに異なりますが、作業を開始する際、存在しない場合のみ以下の構成でセットアップしてください。
  - 作業中は plan と todo を常に更新し続けてください。
  - これらの plan/todo/learn ファイルはコミットしないでください。
  - `.agents/worklog/codex/plan/`: プロジェクトの計画や設計に関するドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_plan.md` のような形式でファイルを作成してください
    - 実装する前に計画を立て、必要であればユーザへの質問を行って計画用のドキュメントを更新してください。
  - `.agents/worklog/codex/todo/`: タスク管理用のディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_todo.md` のような形式でファイルを作成してください
    - `.agents/worklog/codex/plan/` ディレクトリのドキュメントをもとに、実装するタスクを洗い出して記述してください。
    - タスクは完了したら完了済みのセクションに移動してください。todo 全体が完了したら、ファイル名を `$(date +%Y%m%d_%H%M%S)_done.md` のように変更してください。
    - タスクの完了に伴って計画が変更された場合は、`.agents/worklog/codex/plan/` ディレクトリのドキュメントを更新してください。
  - `.agents/worklog/codex/learn/`: 学習用のドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_learn.md` のような形式でファイルを作成してください
    - プロジェクトの実装に必要な知識や技術を学習した際に、学習内容をこのディレクトリに記録してください。
    - 学習内容はプロジェクトの実装に活かせるように、必要に応じて `.agents/worklog/codex/plan/` ディレクトリのドキュメントを更新してください。
    - learn は「次回の意思決定を速くする情報」が得られたときに更新してください。
    - learn には「何を学んだか」「どこに反映すべきか」を必ず書いてください。
    - learn を更新したら、必要に応じて plan の `Assumptions` / `Design` / `Tests` を更新してください。
    - `.agents/worklog/codex/learn/learn_index.md`: learn ファイルの要約インデックス。learn ファイルを新規作成・更新・削除した際は、必ずこのインデックスも更新してください。
    - インデックスの各エントリは 1 行で `- [タイトル](ファイル名) — 要約（150 文字以内）` の形式で記述してください。
  - 作成するファイルには以下の最低限の見出しを含めてください。
    - plan: `Goal`, `Scope`, `Assumptions`, `Design`, `Tests`, `Open Questions`
    - todo: `TODO`, `Done`
    - learn: `Date`, `Learnings`, `Plan Updates`

### plan/todo/learn の frontmatter ルール

- `.agents/worklog/codex/plan/*.md` `.agents/worklog/codex/todo/*.md` `.agents/worklog/codex/learn/*.md` の先頭に YAML frontmatter を必須とします。
- 並列実行を前提に、`active` 制約は「リポジトリ全体で 1 件」ではなく「`owner` ごとに 1 件」とします。

#### 共通必須キー

- `type`: `plan | todo | learn`
- `id`: `YYYYMMDD_HHMMSS`
- `owner`: 例 `codex-a`, `codex-b`
- `created_at`: ISO8601
- `updated_at`: ISO8601

#### type ごとの必須キー

- `todo`: `status`, `workstream`, `related_plan`
- `plan`: `status`
- `learn`: `validated`, `apply_to`

#### status 値

- `todo.status`: `active | blocked | done | superseded`
- `plan.status`: `draft | active | done | superseded`
- `learn.validated`: `true | false`

#### 推奨キー（任意）

- `depends_on`: 依存する `todo id` の配列
- `blocked_reason`: `status=blocked` の理由
- `evidence`: ログ/PR/実験結果のパス配列
- `tags`: 任意タグ

#### 運用ルール

- 新規 `todo` 作成時は `owner` を必ず設定してください。
- 各 `owner` は同時に `active` な `todo` を 1 件までにしてください。
- `# TODO` が空になったら `status: done` に更新し、`*_done.md` へリネームしてください。
- `learn` は「再利用可能」かつ「検証済み (`validated: true`)」のときのみ作成してください。
- `learn` 更新時は `apply_to` に反映先（plan/tests）を明記してください。

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。
