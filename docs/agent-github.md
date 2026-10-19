# GitHub App attribution for coding agents

`agent-github` is a Bash 3.2 CLI that uses a GitHub App **user access token** for individual `gh` invocations. It is managed by chezmoi as `~/.local/bin/common/agent-github`, and requires `curl`, `jq`, and `gh` (all already managed or available in this dotfiles setup).

## One-time setup

1. Create a GitHub App named `shunk031-agent-bot` at [GitHub Developer settings](https://github.com/settings/apps/new). Enable **Device Flow** and expiring user access tokens; grant **Pull requests: read/write** and **Issues: read/write** plus other permissions only if necessary.
2. Install the App on the intended user/repositories; installing an App and authorizing a user are separate steps.
3. Copy the App **Client ID**, not the App ID or Client Secret, and run:

   ```bash
   agent-github login --client-id YOUR_CLIENT_ID
   agent-github status
   ```

4. Visit the printed device verification URL and authorize as `shunk031`. The CLI verifies the account before saving credentials. To confirm the actual App badge in GitHub's UI, inspect a separately approved test write; `gh api user` alone identifies the user, not the App that issued the token.

Device Flow does not require storing a Client Secret or private key in dotfiles. GitHub permits a refresh token created by Device Flow to be exchanged without a Client Secret.

## API operations

```bash
agent-github gh pr create --fill
agent-github gh pr comment 123 --body 'Comment text'
agent-github gh issue create --title 'Title' --body 'Body'
agent-github logout
```

Use the companion `shunk031-github-agent-identity` skill in `shunk031/skills` for agent-specific GitHub API write guidance. Codex and Claude Code keep their normal launch commands. Ordinary `gh` remains authenticated using the user's existing selected account; `agent-github gh` injects the App user token into only the child `gh` process.

Credentials are stored in `${XDG_CONFIG_HOME:-$HOME/.config}/shunk031-agent-bot/auth.json` with restrictive permissions. Automatic refresh replaces tokens atomically under a directory lock. If a process was killed while holding the lock, check for active sessions before manually removing `auth.lock`. `agent-github logout` deletes the local state but does not revoke GitHub authorization. `agent-github token` prints a **secret** and should never be included in logs.

## Semantics and limitations

- The API operation is attributed to `shunk031` via the App's user-to-server token, with an App badge on supported GitHub surfaces. GitHub does not promise the literal phrase `shunk031 with shunk031-agent-bot` everywhere. This is **not** an installation bot acting as `shunk031-agent-bot[bot]`.
- This tool covers GitHub API calls using `gh`, not `git commit`, Git author/committer settings, SSH authentication, or `git push`. The dotfiles' `pushInsteadOf` SSH rewrite is left unchanged.
- The Skill is guidance, not credential isolation. An agent can bypass it by invoking another API client; hard isolation needs sandboxing and separately inaccessible human credentials.
- On any CLI authentication or token refresh failure the command fails without falling back to the user's personal GitHub credentials.

See [GitHub's User Access Token documentation](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-user-access-token-for-a-github-app) and [GitHub's App attribution documentation](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-with-a-github-app-on-behalf-of-a-user).
