# AGENTS.md

## ユーザーへの質問

- ユーザが提供した情報に基づいて、最適な解決策を提案するための質問を行ってください。

## git について

- git commit メッセージは conventional commit 形式で書いてください。

## プロジェクトの構成について

- プロジェクト構成はプログラミング言語ごとに異なりますが、作業を開始する際、存在しない場合のみ以下の構成でセットアップしてください。
  - 作業中は plan と todo を常に更新し続けてください。
  - これらの plan/todo/learn ファイルはコミットしないでください。
  - `docs/plan/`: プロジェクトの計画や設計に関するドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_plan.md` のような形式でファイルを作成してください
    - 実装する前に計画を立て、必要であればユーザへの質問を行って計画用のドキュメントを更新してください。
  - `docs/todo/`: タスク管理用のディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_todo.md` のような形式でファイルを作成してください
    - `docs/plan/` ディレクトリのドキュメントをもとに、実装するタスクを洗い出して記述してください。
    - タスクは完了したら完了済みのセクションに移動してください。todo 全体が完了したら、ファイル名を `$(date +%Y%m%d_%H%M%S)_done.md` のように変更してください。
    - タスクの完了に伴って計画が変更された場合は、`docs/plan/` ディレクトリのドキュメントを更新してください。
  - `docs/learn/`: 学習用のドキュメントを格納するディレクトリ
    - `$(date +%Y%m%d_%H%M%S)_learn.md` のような形式でファイルを作成してください
    - プロジェクトの実装に必要な知識や技術を学習した際に、学習内容をこのディレクトリに記録してください。
    - 学習内容はプロジェクトの実装に活かせるように、必要に応じて `docs/plan/` ディレクトリのドキュメントを更新してください。
  - 作成するファイルには以下の最低限の見出しを含めてください。
    - plan: `Goal`, `Scope`, `Assumptions`, `Design`, `Tests`, `Open Questions`
    - todo: `TODO`, `Done`
    - learn: `Date`, `Learnings`, `Plan Updates`

## コーディング全般について

- エラーを恐れないでください。まずは例外処理は気にせずコードを書いてください。
- 最終成果物でも例外処理は入れなくて構いません。
- 研究開発用途が主なため後方互換性は気にしないでください。あらかじめテストを記述し、テストが通ることを確認してから、必要に応じてコードをリファクタリングしてください。

## Python が主なプロジェクトについて

### `uv` の使用

- Python プロジェクトの場合は指定がない場合常に `uv` を使うようにしてください。
- コードの振る舞いに影響する変更がある場合は必ずテストを記述して意図した動作になっているか確認してください。
- uv でスクリプトを実行するときは `uv run <script>` で実行できます。

### dev 用依存ツール

- `uv add --group dev ruff pytest pytest-cov mypy ty vulture pre-commit` を開発用依存ツールを追加してください。
- 追加したら `pre-commit install` を実行して、コミット前にコード品質チェックが走るようにしてください。
  - もし `.pre-commit-config.yaml` が存在しない場合は、下記の参考実装を作成してください。
  - もし `Makefile` がない場合は作成して、`make setup` で `uv sync` の実行と `pre-commit install` の実行を行う `setup` ターゲットを追加してください。

### pre-commit の使用

- 以下のような `.pre-commit-config.yaml` をプロジェクトのルートディレクトリに作成してください。
- `pytest` の `--cov` は `<package>` を推奨します（例: `--cov=src`）。

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-added-large-files

  - repo: https://github.com/jendrikseipp/vulture
    hooks:
      - id: vulture

  - repo: local
    hooks:
      - id: ruff
        name: ruff (uv)
        entry: uv run ruff check --fix --exit-non-zero-on-fix
        language: system
        types_or: [python, pyi]

      - id: ruff-format
        name: ruff format (uv)
        entry: uv run ruff format
        language: system
        types_or: [python, pyi]

      - id: pytest
        name: pytest (uv)
        entry: uv run pytest -vsx --cov=<package>  # 例: --cov=src
        language: system
        pass_filenames: false
```

### 探索的なデバッグ

- `uv run python -c "..."` のように、`uv` を使って一時的にコードを実行することができます。
- プロジェクトに依存しないライブラリを一時的にインストールして試す場合は `uv run --with <library> python -c "..."` のようにしてください。

### オリジナル実装からのリファクタリングについて

- まずオリジナル実装が uv を使っていない場合、uv を使って動作するようにしてください。
  - オリジナルのコードに必要な依存は `uv add --optional original-impl <module>` のように追加してください
- テストがない場合はテストを追加してください。
  - このとき `pytest-cov` を使ってカバレッジを測定してください。
  - まずは主要な機能をカバーするテストを記述し、その後カバレッジが 90% 以上になるようにテストを追加してください。
- モックやモンキーパッチは使用せず、可能な限り README.md 等に指定されている実データを少量使ってテストを記述してください。
  - 実データのダウンロードはためらわず、既存レポジトリの README.md に記載されている手順に従ってください。
- テストが書けたらオリジナルの実装とリファクタリング後の実装が同じ動作をするか確認してください。
  - オリジナルの実装の出力とリファクタリング後の実装の出力が同じであることを確認してください。
  - 既存実装の出力を pickle などで保存しておいて、リファクタリング後の実装の出力と比較する方法もあります。

## その他のプログラミング言語が主なプロジェクトについて

- 新しい言語を扱う場合は、このセクション配下に方針やルールを追記してください。
