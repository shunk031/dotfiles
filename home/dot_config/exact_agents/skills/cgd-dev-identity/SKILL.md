---
name: cgd-dev-identity
description: Use this skill for all GitHub write operations in creative-graphic-design organization repositories (such as design-generators), including git commits and pushes, PR creation and updates, issue and PR comments, labels, milestones, and user-requested merges. Perform them as the creative-graphic-design-dev machine user. Use it both when the user explicitly requests the bot or dev account and whenever beginning write work in an organization repository without an explicit request.
---

# CGD Dev Identity

## Overview

Perform git and gh write operations for creative-graphic-design organization repositories as the `creative-graphic-design-dev` machine user (user ID 176740601), not a personal account. A bot-authored PR lets a human account formally review and approve it. Because GitHub does not permit users to approve their own PRs, creating a PR with a personal account would prevent the review flow from working.

## Setup

Before starting write operations, perform the following checks in the working shell and worktree. Run them as a starting procedure rather than investigating only after a failure.

1. Pass the bot token to each write command that uses gh or git credentials. The token is distributed to all shells as `CGD_DEV_GH_TOKEN` (managed by zshenv_private):

   ```bash
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh pr create ...
   GH_TOKEN="$CGD_DEV_GH_TOKEN" git push
   ```

   For manual work in a persistent shell, you may use the following shorthand:

   ```bash
   export GH_TOKEN="$CGD_DEV_GH_TOKEN"
   ```

   In environments that start a new shell for each command, such as Claude Code's shell tool, `export` does not persist to the next command. Use the per-command prefix as the canonical approach.

2. Verify the GitHub identity and push permission for the organization repository. `gh api user` only confirms the logged-in account and cannot verify access to organization resources:

   ```bash
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh api user --jq .login
   GH_TOKEN="$CGD_DEV_GH_TOKEN" gh api repos/creative-graphic-design/<repo> --jq .permissions.push
   ```

   Do not start write operations unless the first command returns `creative-graphic-design-dev` and the second returns `true`.

3. Set the commit author to the bot for each commit command:

   ```bash
   git -c user.name=creative-graphic-design-dev \
       -c user.email=176740601+creative-graphic-design-dev@users.noreply.github.com \
       commit ...
   ```

   Do not use `git config user.name/email` in a linked worktree: it writes to the shared `.git/config` and changes the author for the main checkout and concurrent worktrees as well.

4. Push over HTTPS because SSH does not use the proxy in this environment. Set an explicit push URL:

   ```bash
   git remote set-url --push origin https://github.com/creative-graphic-design/<repo>
   ```

`GH_TOKEN` applies to both gh and the git credential helper in the same command environment. The credential helper returns the token with the username `x-access-token`.

## Scope

- This skill applies only to creative-graphic-design organization repositories. Do not use it for other organizations or personal repositories; use normal authentication there. The token is a fine-grained PAT that works only for authorized repositories in the organization, so passing `GH_TOKEN` in an out-of-scope repository causes an authentication error.
- Attribute every coding-agent write to an organization repository to the bot. This includes commits, pushes, PR creation and updates, PR replies, issue comments, labels, milestones, and user-requested merges.
- The human (`shunk031`) retains only PR approval in the GitHub UI and the decision to merge. Do not approve PRs as the bot.

## Troubleshooting

- If an organization-resource endpoint (the repos API or a push) returns 403 with “organization forbids ... lifetime greater than 366 days,” organization policy requires the token lifetime to be no longer than one year. `gh api user` still succeeds in this state, so do not use it to diagnose the issue. Change the token expiration to within one year; the token value itself can remain the same.
- If the token expires, reissue a fine-grained PAT as the creative-graphic-design-dev account with Contents, Pull requests, Issues, and Workflows set to Read and write and access limited to the target repositories. Then update the `CGD_DEV_GH_TOKEN` line in zshenv_private.
- To add a repository to the scope, add it under the PAT's Repository access. Reissuing the token is unnecessary; changing its configuration is sufficient.
