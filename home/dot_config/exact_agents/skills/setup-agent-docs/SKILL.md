---
name: setup-agent-docs
description: リポジトリを coding agent 対応にするときの agent ドキュメント配線パターン(AGENTS.md を source of truth にし、CLAUDE.md は symlink にする)。新しいリポジトリのエージェント対応、coding agent ready 化、AGENTS.md / CLAUDE.md の新規作成・変換・整理、repo-local skill の設置、「エージェント向けドキュメントを整備して」という依頼のときに必ず使う。CLAUDE.md だけ・AGENTS.md だけを作ろうとしている場合もこの skill で配線を確認する。
---

# setup-agent-docs

リポジトリに agent 向けドキュメントを配線するときの標準パターン。Claude Code / Codex など複数の coding agent が同じ実体を読み、重複や乖離が生まれないようにする。

## 配線ルール

- AGENTS.md が source of truth: リポジトリ直下に `AGENTS.md` を置き、agent 向けの規約・手順はすべてここに書く。冒頭に読了マーカーを置く:

  ```markdown
  > [!NOTE]
  > After reading this AGENTS.md, say: 🤖 I read the AGENTS.md for <owner>/<repo>.
  ```

- リポジトリ固有の内容だけ書く: グローバル `~/.agents/AGENTS.md` に既にあるルール(uv 必須、worktree 方針、例外処理方針など)は再掲しない。再掲すると更新時に乖離する。

- CLAUDE.md は AGENTS.md への相対 symlink にする: `@AGENTS.md` と書いた通常ファイルにはしない。

  ```shell
  ln -s AGENTS.md CLAUDE.md
  git add CLAUDE.md   # mode 120000 で追跡されることを確認: git ls-files -s CLAUDE.md
  ```

  symlink にする理由: Claude Code・Codex・その他ツールが同一実体を読むため、import 記法の対応差やコピー乖離が発生しない。

- repo-local skill の配線: skill の source of truth は `.agents/skills/<name>/SKILL.md` に置き、`.claude/skills` は相対 symlink としてコミットする。

  ```shell
  mkdir -p .agents/skills
  ln -s ../.agents/skills .claude/skills
  ```

  Codex は Claude の skill 機構を持たないが、SKILL.md はただの Markdown なので、AGENTS.md から `.agents/skills/<name>/SKILL.md` のパス参照で同じ手順を辿らせる。

- private 境界: 社内ネットワーク、起動プロファイル、proxy 事情などの private 情報はリポジトリに一切書かない。必要な箇所には「環境固有の設定は `~/.agents/AGENTS-private.md` の該当節を参照」というポインタだけを置く。グローバル AGENTS.md が AGENTS-private.md の読み込みを指示しているため、ポインタだけで agent は辿れる。

## 参考実装

https://github.com/haralab-uec/kitada-experiments — `AGENTS.md`、`CLAUDE.md`(symlink)、`.agents/skills/`、`.claude/skills`(symlink)の実例。
