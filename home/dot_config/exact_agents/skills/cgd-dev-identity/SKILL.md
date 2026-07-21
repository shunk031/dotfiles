---
name: cgd-dev-identity
description: creative-graphic-design org のリポジトリ(design-generators など)で git commit、push、PR 作成・更新、issue / PR コメントなどの GitHub write を行うときは、必ずこの skill に従って machine user creative-graphic-design-dev として実行する。「bot として push」「dev アカウントで」「creative-graphic-design-dev で」と言われたときはもちろん、org 配下リポジトリへの write 作業を始めるとき全般で、明示指定がなくても必ず使う。
---

# CGD Dev Identity

## Overview

creative-graphic-design org のリポジトリに対する git / gh の write 操作は、個人アカウントではなく machine user `creative-graphic-design-dev`(user id 176740601)として実行する。PR が bot 名義になることで、人間のアカウントがその PR を正式にレビュー・承認できる。GitHub では自分の PR を自分では承認できないため、個人アカウント名義で PR を作るとレビューフローが成立しない。

## Setup

write 操作を始める前に、作業シェルと worktree で以下を設定する。失敗してから調べるのではなく、開始手順として実行する。

1. gh / git credential を bot トークンに切り替える。トークンは全シェルに `CGD_DEV_GH_TOKEN` として配布済み(zshenv_private 管理):

   ```bash
   export GH_TOKEN="$CGD_DEV_GH_TOKEN"
   ```

2. 切り替わったことを確認する。`creative-graphic-design-dev` が返らなければ write を始めない:

   ```bash
   gh api user --jq .login
   ```

3. commit author を bot にする(作業 worktree ごと):

   ```bash
   git config user.name creative-graphic-design-dev
   git config user.email 176740601+creative-graphic-design-dev@users.noreply.github.com
   ```

4. push は HTTPS で行う(この環境の SSH は proxy を通らない)。explicit pushurl を設定する:

   ```bash
   git remote set-url --push origin https://github.com/creative-graphic-design/<repo>
   ```

`GH_TOKEN` はそのシェルの gh と git credential helper の両方に効く。credential helper は username `x-access-token` でトークンを返す。

## Scope

- 対象は creative-graphic-design org のリポジトリのみ。他 org・個人リポジトリではこの skill を使わず、通常の認証のまま作業する。トークンは fine-grained PAT で org 内の許可リポジトリにしか効かないため、対象外リポジトリで `GH_TOKEN` を export したままにすると認証エラーになる。
- bot が行うのは実装系の write(commit、push、PR 作成・更新、PR への返信、issue コメント、label)まで。PR の承認と merge の判断は人間のアカウントの仕事であり、bot で PR を approve しない。

## Troubleshooting

- `gh api user` が 403 で「organization forbids ... lifetime greater than 366 days」を返す場合、org ポリシーによりトークンの有効期限が 1 年を超えている。トークンの expiration を 1 年以内に変更すれば同じ値のまま通る。
- トークンが失効した場合は、creative-graphic-design-dev アカウントで fine-grained PAT(Contents / Pull requests / Issues / Workflows を Read and write、対象リポジトリ限定)を再発行し、zshenv_private の `CGD_DEV_GH_TOKEN` 行を更新する。
- 新しいリポジトリを対象に加える場合は、PAT の Repository access にそのリポジトリを追加する必要がある。トークン再発行は不要で、設定変更のみでよい。
