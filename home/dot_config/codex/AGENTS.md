# AGENTS.md

> [!NOTE]
> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`

- 共通指示: `~/.agents/AGENTS.md` を最初に読み、その内容をこの Codex 固有 entrypoint と合わせて適用してください。
- private 指示: `~/.agents/AGENTS-private.md` が読める場合は、そこにある Codex の環境固有設定も適用してください。

## Codex 固有の委譲

- 標準機能: 調査と実装の委譲には Codex の native subagents を使い、別プロセスの委譲基盤を追加しないでください。
- GitHub workflow: branch、commit、push、pull request、CI確認は、利用可能な場合 `gh-workflow-manager` custom agent に委譲してください。
