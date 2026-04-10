# AGENTS.md

## 応答ルール

- この `AGENTS.md` を読んだら「🤖 私は shunk031/dotfiles 向け AGENTS.md を読みました。」と言ってください。

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## プロジェクトの構成について

- プロジェクト構成はプログラミング言語ごとに異なりますが、作業を開始する際、存在しない場合のみ以下の構成でセットアップしてください。
  - 作業中は plan と todo を常に更新し続けてください。
  - これらの plan/todo/learn ファイルはコミットしないでください。
  - `docs/codex/plan/`: プロジェクトの計画や設計に関するドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_plan.md` のような形式でファイルを作成してください
    - 実装する前に計画を立て、必要であればユーザへの質問を行って計画用のドキュメントを更新してください。
  - `docs/codex/todo/`: タスク管理用のディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_todo.md` のような形式でファイルを作成してください
    - `docs/codex/plan/` ディレクトリのドキュメントをもとに、実装するタスクを洗い出して記述してください。
    - タスクは完了したら完了済みのセクションに移動してください。todo 全体が完了したら、ファイル名を `$(date +%Y%m%d_%H%M%S)_done.md` のように変更してください。
    - タスクの完了に伴って計画が変更された場合は、`docs/codex/plan/` ディレクトリのドキュメントを更新してください。
  - `docs/codex/learn/`: 学習用のドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_learn.md` のような形式でファイルを作成してください
    - プロジェクトの実装に必要な知識や技術を学習した際に、学習内容をこのディレクトリに記録してください。
    - 学習内容はプロジェクトの実装に活かせるように、必要に応じて `docs/codex/plan/` ディレクトリのドキュメントを更新してください。
    - learn は「次回の意思決定を速くする情報」が得られたときに更新してください。
    - learn には「何を学んだか」「どこに反映すべきか」を必ず書いてください。
    - learn を更新したら、必要に応じて plan の `Assumptions` / `Design` / `Tests` を更新してください。
  - 作成するファイルには以下の最低限の見出しを含めてください。
    - plan: `Goal`, `Scope`, `Assumptions`, `Design`, `Tests`, `Open Questions`
    - todo: `TODO`, `Done`
    - learn: `Date`, `Learnings`, `Plan Updates`

### plan/todo/learn の frontmatter ルール

- `docs/codex/plan/*.md` `docs/codex/todo/*.md` `docs/codex/learn/*.md` の先頭に YAML frontmatter を必須とします。
- 並列実行を前提に、`active` 制約は「リポジトリ全体で1件」ではなく「`owner` ごとに1件」とします。

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
- 各 `owner` は同時に `active` な `todo` を1件までにしてください。
- `# TODO` が空になったら `status: done` に更新し、`*_done.md` へリネームしてください。
- `learn` は「再利用可能」かつ「検証済み (`validated: true`)」のときのみ作成してください。
- `learn` 更新時は `apply_to` に反映先（plan/tests）を明記してください。

#### 既存ファイルの最小移行ルール

- 既存の `docs/codex/todo/*_todo.md` / `docs/codex/todo/*_done.md` は、次回編集時に frontmatter を追加してください。
- 既存ファイルで `owner` が不明な場合は一時的に `owner: unknown` を設定してください。
- 既存 `*_done.md` は `status: done` を設定してください。
- 既存 `*_todo.md` で `# TODO` が空の場合は `status: done` に更新し、`*_done.md` へリネームしてください。
- `created_at` はファイル名のタイムスタンプを優先し、不明な場合のみ現在時刻を使用してください。

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

## テスト方針

- `bats` によるテストはローカルでは実行しないでください。
- `bats` の結果確認が必要な場合は GitHub へ push して GitHub Actions の CI を起動し、その実行結果を確認してください。
