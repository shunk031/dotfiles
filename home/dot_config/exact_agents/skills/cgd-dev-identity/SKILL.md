---
name: cgd-dev-identity
description: creative-graphic-design org のリポジトリ(design-generators など)で git commit、push、PR 作成・更新、issue / PR コメント、label / milestone、ユーザー指示による merge 実行などの GitHub write を行うときは、必ずこの skill に従って machine user creative-graphic-design-dev として実行する。「bot として push」「dev アカウントで」「creative-graphic-design-dev で」と言われたときはもちろん、org 配下リポジトリへの write 作業を始めるとき全般で、明示指定がなくても必ず使う。
---

# CGD Dev Identity

## Overview

creative-graphic-design org のリポジトリに対する git / gh の write 操作は、個人アカウントではなく machine user `creative-graphic-design-dev`(user id 176740601)として実行する。PR が bot 名義になることで、人間のアカウントがその PR を正式にレビュー・承認できる。GitHub では自分の PR を自分では承認できないため、個人アカウント名義で PR を作るとレビューフローが成立しない。

## Setup

write 操作を始める前に、作業シェルと worktree で以下を確認する。失敗してから調べるのではなく、開始手順として実行する。

1. gh / git credential を使う write 系コマンドには、per-command で bot トークンを渡す。トークンは全シェルに `CGD_DEV_GH_TOKEN` として配布済み(zshenv_private 管理):

   ```bash
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh pr create ...
   GH_TOKEN="$CGD_DEV_GH_TOKEN" git push
   ```

   同じ shell が持続する手動作業では、以下を省略記法として使ってよい:

   ```bash
   export GH_TOKEN="$CGD_DEV_GH_TOKEN"
   ```

   Claude Code / Codex の shell tool のようにコマンドごとに新しい shell が立つ環境では `export` は次のコマンドへ持続しないため、per-command prefix を正とする。

2. GitHub identity と org repository の push 権限を確認する。`gh api user` はログイン中のアカウント確認にしかならず、org リソースへのアクセス可否は検証できない:

   ```bash
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh api user --jq .login
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh api repos/creative-graphic-design/<repo> --jq .permissions.push
   ```

   1 つ目のコマンドで `creative-graphic-design-dev`、2 つ目のコマンドで `true` が返らなければ write を始めない。

3. commit author は commit 実行時に per-command で bot にする:

   ```bash
   git -c user.name=creative-graphic-design-dev \
       -c user.email=176740601+creative-graphic-design-dev@users.noreply.github.com \
       commit ...
   ```

   linked worktree で `git config user.name/email` を使うと共有 `.git/config` に書き込まれ、main checkout や並行 worktree の author まで bot に変わるため使わない。

4. push は HTTPS で行う(この環境の SSH は proxy を通らない)。explicit pushurl を設定する:

   ```bash
   git remote set-url --push origin https://github.com/creative-graphic-design/<repo>
   ```

`GH_TOKEN` は同じコマンド環境の gh と git credential helper の両方に効く。credential helper は username `x-access-token` でトークンを返す。

## Scope

- 対象は creative-graphic-design org のリポジトリのみ。他 org・個人リポジトリではこの skill を使わず、通常の認証のまま作業する。トークンは fine-grained PAT で org 内の許可リポジトリにしか効かないため、対象外リポジトリで `GH_TOKEN` を渡したままにすると認証エラーになる。
- coding agent が行う org リポジトリへの write はすべて bot 名義にする。対象には commit、push、PR 作成・更新、PR への返信、issue コメント、label、milestone、およびユーザー指示による merge の実行を含む。
- 人間(`shunk031`)に残るのは GitHub UI 上での PR approve と merge 判断のみ。bot で PR を approve しない。

## Troubleshooting

- org リソースのエンドポイント(repos API や push)で 403 が返り、「organization forbids ... lifetime greater than 366 days」と表示される場合、org ポリシーによりトークンの有効期限が 1 年を超えている。`gh api user` はこの状態でも成功するため判定に使えない。トークンの expiration を 1 年以内に変更すれば同じ値のまま通る。
- トークンが失効した場合は、creative-graphic-design-dev アカウントで fine-grained PAT(Contents / Pull requests / Issues / Workflows を Read and write、対象リポジトリ限定)を再発行し、zshenv_private の `CGD_DEV_GH_TOKEN` 行を更新する。
- 新しいリポジトリを対象に加える場合は、PAT の Repository access にそのリポジトリを追加する必要がある。トークン再発行は不要で、設定変更のみでよい。
