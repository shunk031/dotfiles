# GitHub Copilot Instructions for Dotfiles Repository

This document provides guidelines for using GitHub Copilot effectively within this dotfiles repository. Adhering to these instructions will help maintain consistency, improve code quality, and ensure that generated suggestions align with our project's standards, especially regarding Conventional Commits.

---

## 1. General Best Practices

* **Be Specific with Prompts:** The more precise your comments and existing code, the better Copilot can understand your intent. Clearly describe what you want to achieve.
* **Review Suggestions Carefully:** Always review Copilot's suggestions before accepting them. Don't blindly accept code; ensure it's correct, efficient, and aligns with your overall goal.
* **Iterate and Refine:** If the initial suggestion isn't perfect, refine your prompt or add more context. Copilot often improves with more specific input.
* **Focus on Small, Incremental Changes:** Try to break down complex tasks into smaller, manageable chunks. This makes it easier for Copilot to provide relevant suggestions and for you to review them.

---

## 2. Conventional Commits Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages. This helps us maintain a clear and consistent commit history, which is crucial for changelog generation and understanding project evolution.

When using Copilot, pay close attention to the following for commit-related suggestions:

* **Commit Type:** Start your commit message with a **type**, followed by an optional **scope**, and a colon and space.
    * **Common types for dotfiles:**
        * `feat`: A new feature or configuration.
        * `fix`: A bug fix or correction to an existing configuration.
        * `docs`: Documentation only changes.
        * `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semicolons, etc.).
        * `refactor`: A code change that neither fixes a bug nor adds a feature (e.g., restructuring files, renaming variables).
        * `perf`: A code change that improves performance.
        * `test`: Adding missing tests or correcting existing tests.
        * `build`: Changes that affect the build system or external dependencies (e.g., `deps`, `npm`).
        * `ci`: Changes to our CI configuration files and scripts.
        * `chore`: Other changes that don't modify src or test files (e.g., updating grunt tasks, `.gitignore`).
    * **Example:** `feat: Add new Zsh aliases`
    * **Example with scope:** `fix(vim): Correct keybinding for split window`

* **Commit Subject:** Follow the type/scope with a **short, imperative, present-tense** description of the change.
    * **Bad:** `added new feature`
    * **Good:** `feat: Add new feature`
    * **Good:** `fix: Correct typo in README`

* **Commit Body (Optional):** If the change is complex, include a blank line after the subject and then a more detailed explanation in the commit body.
    * **Wrap at 72 characters** for readability.
    * **Use imperative mood:** "Add feature" not "Added feature".

* **Breaking Changes (Optional):** For breaking changes, start a paragraph with `BREAKING CHANGE:` followed by a description of the change and justification. This should be in the footer of the commit.

---

## 3. Dotfiles Specific Considerations

* **Context is Key:** Dotfiles often rely heavily on context from your shell, editor, or other applications. Provide comments that explain the purpose of specific configurations.
    ```bash
    # Ensure Copilot understands this is for Zsh
    # Auto-suggestion plugin configuration
    zsh_autosuggestions_config() {
        # ...
    }
    ```
* **Idempotency:** Many dotfile configurations should be idempotent (running them multiple times has the same effect as running them once). Copilot can help suggest idempotent patterns if you provide the right context.
* **Security:** Be mindful of sensitive information. Dotfiles can sometimes contain API keys or personal data. Ensure Copilot doesn't suggest sensitive information that shouldn't be committed.
* **Cross-Platform Compatibility:** If your dotfiles are meant to be cross-platform, include comments indicating specific OS or environment dependencies.

---

## 4. Troubleshooting & Tips

* **Copilot not suggesting Conventional Commits?** Try explicitly typing the type (e.g., `feat:`) and Copilot might pick up the pattern.
* **Too many irrelevant suggestions?** Try restarting your editor or the Copilot extension. Sometimes providing more surrounding code context helps.
* **Provide examples:** If you have existing commit messages that follow Conventional Commits, Copilot will learn from them.
