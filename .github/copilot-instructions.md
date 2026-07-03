# GitHub Copilot Instructions

- Primary instructions: Read [`AGENTS.md`](../AGENTS.md) at the repository root and follow it. It is the source of truth for repository context, comment policy, Git / PR workflow, and test policy.
- Repository context: This is a [`chezmoi`](https://www.chezmoi.io/)-managed dotfiles repository. Files under `home/` are the public source state applied into the user's `$HOME`; see the `Repository Context` section of `AGENTS.md` before proposing changes.
- Commit messages: Follow the `Commit messages` rule in `AGENTS.md` (Conventional Commits, `<type>(<scope>): <summary>`, lowercase imperative summary).
- Security: Never suggest or commit secrets, API keys, or other personal data. Private dotfiles are managed outside this repository.
