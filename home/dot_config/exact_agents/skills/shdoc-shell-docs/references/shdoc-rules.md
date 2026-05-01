# Shdoc Rules

Use this reference when the target file needs `shdoc`-compatible comments.

## Canonical Sources

- Use the official `shdoc` README as the source of truth for supported tags and formatting.
- Use `scripts/generate-docs.sh` as the local style baseline in this repository.
- Prefer `@file` over `@name` here because the repo example already uses `@file`.

## Minimal File Header

Use file-level annotations near the top of the script when the file is a meaningful entrypoint or library.

```bash
#!/usr/bin/env bash

# @file scripts/example.sh
# @brief Explain the script purpose in one line.
# @description
#   Add extra context only when the overall workflow needs it.
```

Guidelines:

- Keep `@brief` to one sentence.
- Use multiline `@description` for scope, side effects, or generated-doc context.
- Omit the long description when the brief is enough.

## Function Annotation Pattern

Document non-trivial functions directly above the definition.

```bash
# @description Build the output path for a source file.
# @arg $1 path Source file path relative to the repository root.
function output_path_for_source() {
    local source_path="$1"
}
```

Add more tags only when they describe observable behavior:

- `@arg`: positional parameters such as `$1`
- `@option`: supported flags or option-value pairs
- `@example`: invocation examples that clarify usage
- `@stdout` and `@stderr`: meaningful output contracts
- `@exitcode`: non-obvious return codes
- `@see`: related functions or docs

## Option and Example Pattern

```bash
# @description Lint one shell script for missing annotations.
# @option -n | --dry-run Print findings without modifying files.
# @arg $1 path Target shell script.
# @example
#   lint_shdoc --dry-run scripts/generate-docs.sh
function lint_shdoc() {
    local target="$1"
}
```

## Repo-Specific Cues

- A standalone `#` spacer line above a documented function is acceptable when it improves readability.
- Phrase descriptions around what the function or script does for the caller.
- Match argument names to the implementation, for example `path`, `string`, or `group`.
- Preserve accurate existing wording when possible and normalize the format first.

## Common Mistakes

- Do not invent flags, parameters, or exit codes that the function does not implement.
- Do not duplicate the same prose in both raw comments and `shdoc` tags.
- Do not add documentation noise to tiny helpers whose name and body are already obvious.
- Do not describe hidden implementation details when callers only need behavior.
