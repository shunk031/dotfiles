# Commit changes to Git

- Step 1: Review all the uncommited changes in the current session.
- Step 2: Notify the user if there are:
  - Files with security concerns
  - Files with temporary changes
- Step 3: If there are files detected in Step 2, stop and let the user decise what to do next. Else, process to step 4.
- Step 4: Add only the files relevant to the current task to staging. Never stage unrelated staged, unstaged, or untracked changes; if unrelated changes exist, list the files you are leaving out. Respect .gitignore and similar files.
- Step 5: Write a commit message following Conventional Commits guideline below
- Step 6: Ask if user approves the message. Give 3 options:
  - Approve
  - Regenerate
  - I will write the commit message myself
- Step 7:
  - If user chose Approve on step 6, commit the changes with the generated message.
  - If user chose Regenerate, re-run from step 5.
  - If user chose to write commit message themselves, run `git commit`. It should open a text editor so that the user can write their commit message.

# Conventional Commits guideline

Follow the `Commit messages` rule in the repository `AGENTS.md` when present; otherwise use the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) summary below.

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- Types: `feat` (new feature, SemVer MINOR), `fix` (bug fix, SemVer PATCH), plus `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`, and others.
- Description: lowercase, imperative, and immediately after the `<type>(<scope>): ` prefix, e.g. `fix(parser): handle multiple spaces in string`.
- Body: optional free-form paragraphs, starting one blank line after the description.
- Footers: optional git-trailer style lines, e.g. `Refs: #123`.
- Breaking changes: mark with `!` after the type/scope (`feat(api)!: ...`) or an uppercase `BREAKING CHANGE:` footer (SemVer MAJOR).
