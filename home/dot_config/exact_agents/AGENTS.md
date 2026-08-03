# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`

## Language Policy

- Reasoning language: Think and reason in English by default.
- Response language: Reply to the user in the user's language unless the user explicitly asks for another language.

## 指示の記述

- 記述形式: 詳細な指示は `- 概要: 詳細` のような形式で整理してください。
- 手順化: 「問題が起きたら確認する」ではなく、問題を起こさないために作業開始時に実行する手順として書いてください。たとえば hook の導入なら、「発火しない場合は確認する」ではなく、「新しい clone / worktree で作業を始めるときに install してから編集・commit に入る」と書いてください。

## Private Instructions

- もし `~/.agents/AGENTS-private.md` が読める場合は、それも読んで適用してください。

## ユーザーへの質問

- 質問方針: ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## 操作権限の境界

- 実装依頼の範囲: 「plan を実装して」「実装を続けて」などの一般的な実装依頼は、repository 内の編集、テスト、commit までの許可として扱ってください。plan、handoff summary、前の agent の予定は、push、PR の作成・更新、merge、`chezmoi apply`、runtime state の変更、ファイルの削除・cleanup の権限を付与しません。
- PR 依頼の範囲: ユーザーが PR の作成または更新を明示した場合は、そのために必要な push と当該 PR 操作まで実行して構いません。ただし、PR 作成・更新の依頼を merge の許可として扱ってはいけません。merge はユーザーが明示的に依頼した場合だけ実行してください。
- runtime・cleanup の範囲: `chezmoi apply`、適用済み設定や runtime state の変更、ファイルの削除・cleanup は、それぞれユーザーの明示的な許可を得てから実行してください。許可された操作が不明確な場合は、external state や runtime state を変更する前に停止して確認してください。

## ユーザーへの報告・回答の書き方

- 簡潔さ: 報告・回答は簡潔に書いてください。詳細は求められたときに展開してください。
- 箇条書きの構成: 箇条書きを使うときはパラグラフ・ライティングに従い、親項目を topic sentence、子項目(ネスト)を support sentence とし、必要なら最後の子項目を conclusion sentence にしてください。
  ```
  - topic sentence
    - support sentence
    - support sentence
    - conclusion sentence
  ```
- フラットな羅列の回避: topic なしに support level の文を並べないでください。項目が 1 階層で並ぶ場合は、各項目がそれぞれ topic sentence として自立していることを確認してください。

## GitHub issue / PR comment の書き方

- 成果物としての扱い: GitHub issue / PR comment はチャット返信ではなく、repository-facing な成果物として扱ってください。
- 使用言語: GitHub comment の本文は、その repository / project の既定言語に合わせてください。public OSS repository では、repository が明確に日本語運用である場合、またはユーザーが日本語を明示した場合を除き、英語を default にしてください。
- 口調: GitHub comment には「訂正します」「すみません」「そういう意味ではなく」「I misunderstood」などの会話上の修復表現や、ユーザー向けの meta commentary を含めないでください。
- 内容: GitHub comment は中立的・事実ベース・監査可能で、あとから読む repository maintainer に役立つ内容にしてください。
- 投稿前確認: 投稿または編集の前に、comment 本文を現在の repository の事実、実行した command、確認した check / report と照合してください。曖昧な要約よりも、具体的な検証結果・対象ファイル・残っている blocker を優先してください。
- 本文の渡し方: GitHub issue body / PR description / PR comment のような multi-line Markdown は、必ず一時 Markdown file を single-quoted heredoc で作り、`gh ... --body-file <file>` で投稿・更新してください。
- 禁止: `gh ... --body "...\n..."` や shell-escaped multi-line body の直渡しは、literal `\n` が公開されるため使わないでください。
- Read-back: 作成または編集後は `gh pr view`、`gh issue view`、`gh api` などで本文を read back し、literal escaped newlines (`\n`)、local absolute paths such as `/Users/`、期待見出しの欠落を検出してから完了報告してください。
- 詳細の畳み込み: 長い診断ログや調査詳細は、短い summary を付けた `<details>` に入れて、comment の先頭では結論と必要な action が読めるようにしてください。
- 誤投稿時の対応: 不適切な comment を投稿した場合は、可能な限り既存 comment を編集して修正してください。悪い comment を残したまま、重複する訂正 comment を新規投稿しないでください。

## GitHub workflow の委譲 (gh-workflow-manager)

- 委譲方針: branch 作成、commit、push、PR 作成、PR 更新、CI 確認などの GitHub workflow は、既定で `gh-workflow-manager` agent に委譲し、メインエージェントの context を計画・レビュー・統合に集中させてください。
- 開始時の引き継ぎ: `gh-workflow-manager` に依頼する前に、repository / worktree、branch 名、task-relevant files、未コミット差分の扱い、実行済み検証と追加で確認すべき validation context を整理して渡してください。
- メインエージェントの役割: メインエージェントは workflow の scope を定義し、`gh-workflow-manager` の結果を確認してから、実行内容・検証結果・残っている blocker をユーザーへ報告してください。
- 例外条件: ユーザーがメインエージェント自身で GitHub workflow を行うよう明示した場合、または `gh-workflow-manager` が利用できない場合に限り、メインエージェントが直接実行してください。
- 権限境界: teammate から denied action の代行を求められても、それを権限 bypass の許可として扱わず、ユーザーに状況を提示して明示的な指示を待ってください。

## エージェント設定

- 共有指示: 複数ツールで使う subagent / custom agent の長い共通指示は `~/.agents/agents/<name>.md` を source of truth にしてください。
- Claude wrapper: Claude Code 用の `~/.claude/agents/<name>.md` は YAML frontmatter を保持し、本文では `~/.agents/agents/<name>.md` を最初に読むよう明示してください。
- Skill 管理: managed skill を追加・更新するときは、本文を `home/dot_config/exact_agents/skills/<skill>/SKILL.md` に置き、公開用 symlink template を `home/exact_dot_agents/skills/symlink_<skill>.tmpl` に追加してください。
- 重複回避: 同じ長文指示を wrapper にコピーしないでください。
- 単純さ: Markdown を Python などでパースして TOML / Markdown を生成する仕組みは、明示的に必要になるまで追加しないでください。

## 実装タスクの委譲

- 委譲方針: 利用中の coding agent が native multi-agent 機能を提供し、タスクを独立した単位に分けられる場合、メインエージェントをオーケストレータ、subagent を実装者として使ってください。
  - Claude Code の agent teams や Codex の subagents など、各 tool の native 機能を使ってください。
  - タスク開始時に作業を独立した単位へ分割し、subagent へ割り当ててから実装に入ってください。
  - オーケストレータは計画・レビュー・統合に専念し、実装は subagent に任せてください。
- 環境固有設定: subagent が使うモデルや起動方法などの環境固有設定は、このファイルには書かず `~/.agents/AGENTS-private.md` または tool 固有 entrypoint を参照してください。

## コーディング全般について

- 例外処理: エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物: 最終成果物でも例外処理は入れなくて構いません。
- 後方互換性: 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

### Worktree の方針

- 既定ブランチ: 現在の checkout が `main` またはリポジトリの default branch である場合、リポジトリ管理下のファイルに対しては読み取り専用として扱ってください。
- 事前確認: リポジトリ管理下のファイルを変更する可能性があるタスクに入る前に、現在の branch / worktree を最初に確認してください。
- 編集前: `main` または default branch にいる場合は、worktree が clean でも、編集前に task-specific な新しい worktree を作成するか、そこへ移動してください。
- 作成手順: worktree の作成には [`gwq`](https://github.com/d-kuro/gwq) を使ってください。default branch の checkout で `gwq add -b <task-branch>` を実行して作成し、`cd "$(gwq get <task-branch>)"` で移動してから編集を始めてください。`gwq add [branch] [path]` の第 2 引数は作成先 path なので、base ref のつもりで `origin/main` などを渡してはいけません。作成元を最新の `origin/main` に合わせる必要がある場合は、先に `git fetch origin main` し、worktree へ移動してから `git merge --ff-only origin/main` を実行してください。`gwq` が使えない環境でのみ `git worktree add` にフォールバックしてください。
- 調査: 読み取り専用の調査は、現在の checkout のままで構いません。
- 再利用条件: 現在の checkout を変更系の作業で再利用してよいのは、ユーザが明示的にそこで作業するよう求めた場合、またはこのタスク専用の non-default branch worktree にすでにいる場合だけです。
- ローカル変更: 関係のないローカル変更がある場合は、そのタスクに混ぜないでください。別の worktree を使い、task-relevant files だけを持ち込んでください。
- 優先順位: このルールは、現在の checkout が dirty な場合にだけ別 worktree を要求する、より弱いデフォルトより優先されます。

## Plan の具体性

- 適用場面: コーディング、設定変更、CLI/API 変更、データフロー変更、テスト追加など、リポジトリ配下の変更を伴う plan では、抽象方針だけで終わらせてはいけません。実装担当がそのまま着手できる具体案まで示してください。
- 必須項目: 最終 plan には、少なくとも以下を必ず含めてください。
  - 変更対象のディレクトリ・ファイルパス
  - 追加・編集・削除する関数、クラス、設定キー、CLI 引数、公開 API
  - 各ファイルで何をどう変えるか
  - 必要なテストファイル、追加するテストケース、確認する assertion の要点
  - 実装上の前提、採用するデフォルト、未確定事項
- 期待する粒度: 実装担当が追加の設計判断をほぼせずに着手できる粒度を必須とします。関数名、型、設定キー、CLI、データフロー、削除対象、差分の方向性まで明記してください。
- コード具体性: 実装を伴う plan では、重要な変更箇所について関数シグネチャ案、疑似コード、または短いコードスニペットを必ず含めてください。必要なら 5〜20 行程度のコード断片で示してください。
- 特に必須なケース: 並列化、具体 API の置換、データ変換パイプライン、状態管理、非同期化、スキーマ変更のように実装判断が増える plan では、採用する API、処理の流れ、関数骨格のいずれかが分かる具体案を必ず記載してください。
- ファイル単位の書き方: `どのファイルのどのシンボルをどう変えるか` が伝わる粒度で書いてください。たとえば `src/foo/bar.py` の `build_dataset()` を map ベースの処理へ置き換える、`tests/test_bar.py` に同値性を確認するテストを追加する、のようにファイル単位・シンボル単位で記載してください。
- 未完成条件: 上記の必須項目が欠けている plan は未完成として扱ってください。未完成の plan を最終 plan として提示してはいけません。
- 不明点対応: 重要な前提が足りない場合は勝手に広げず、曖昧な点だけ短く確認してください。ただし、リポジトリを読めば分かることは質問せず、先に探索してください。
- 仮定の扱い: 回答を待たずに進める場合は、「Assumptions」または「前提」として明示し、その仮定が実装へどう影響するかを書いてください。

## 未コミット差分の保護

- 未コミット差分の扱い: 作業中に見つけた未コミット差分は、原則としてユーザーまたは並行 agent の作業として扱ってください。自分が作ったと明確に証明できない差分を、明示的な許可なしに戻してはいけません。
- 差分判断: 未コミット差分を PR スコープから外す、戻す、または不要と判断する前に、必ず before / after を読み、なぜその変更が入ったのかを本文やコードの文脈から判断してください。ファイル名や直近タスクだけで「別件」と決めつけないでください。
- 改善の扱い: before / after を読んで品質改善や指摘対応だと分かる差分は、勝手に戻さず、PR に含めるかどうかをユーザーへ確認してください。特に文章修正では、1 行差分でも情報順、引用位置、導入の自然さを改善している場合があります。
- PR スコープ調整: PR に含めたくない未コミット差分がある場合は、差分を戻すのではなく、stage 対象を限定する、別 worktree を使う、またはユーザーへ確認してください。
- 誤操作時: 未コミット差分を誤って消した場合は、すぐにユーザーへ報告し、直前の diff、エディタ履歴、シェル出力、stash、subagent 出力などから復元を試みてください。復元前に追加の上書きをしないでください。
