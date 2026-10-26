# Design record: deterministic chezmoi apply and source-safe adapters

Date: 2026-10-26

## Target

- Make public `chezmoi apply` normalize existing managed paths to the source's intended modes regardless of the caller's umask.
- Keep `private_` entries at mode `0600` or `0700`.
- Keep runtime configuration files and directories outside the public source tree so source renames cannot leave application-written files in an obsolete source path.
- Preserve the existing home-facing paths and canonical source files.

## Removals

- Remove the 22 home-facing symlinks that point back into the public source tree, including the relative iTerm2 profile link.
- Replace file links with regular chezmoi templates that include their canonical source content. Replace directory links with managed files under real target directories.
- Keep the content in its current canonical source files; the adapters only render that content into the managed destination.

## Retained elements and reasons

- Keep the `~/.bashrc` link because it targets another applied path in `$HOME`, not the source tree.
- Keep `~/.agents/AGENTS-private.md` linked to the private source because the private repository owns that content. This change does not edit the private repository.
- Keep `.chezmoi.sourceDir` references in apply-time scripts; they locate scripts while chezmoi is running and do not create persistent links in the destination.
- Keep the canonical content, current destination paths, private directory attributes, and existing apply hooks.
- Keep the canonical Antigravity settings in `home/private_dot_config/antigravity-cli/settings.json`; render it to `~/.gemini/antigravity-cli/settings.json` as a regular `0644` file. Source content is authoritative. An edited runtime target is drift: normal apply prompts about the changed target, while `--force` replaces it with the source content and mode.
- Keep the five user-facing agent directories and their managed canonical entries. A read-only `run_before` check blocks apply while untracked or ignored runtime files remain in their old source-linked directories or have unresolved migration backups. The explicit migration helper stages each file or symlink, atomically renames the source entry into a retained backup under `~/.local/state/chezmoi-migration/`, and installs the staged copy at the home target only if the retained entry still matches. It preserves modes and symlink targets, never deletes backups, and reports their location. If the retained entry changes or does not match the target, the helper exits nonzero without replacing an existing target; the guard directs the user to inspect the backup, copy its latest contents to the target, and rerun migration and apply.

## User-owned setting and options

The public chezmoi configuration sets `umask: 18` (`0o022`). This preserves the source's ordinary `0644` file and `0755` directory modes while `private_` attributes still enforce `0600` and `0700`.

- Keep the caller's umask: rejected because identical applies can change modes depending on who runs them.
- Use `0o022`: chosen; matches the public source's ordinary modes and does not weaken `private_` entries.
- Use `0o077`: rejected because it would make ordinary managed files and directories private and would not match the source's intended modes.
- Use `0o002`: rejected because it permits group writes to ordinary managed files.

For Antigravity settings, the source file `home/private_dot_config/antigravity-cli/settings.json` is canonical and the rendered target mode is `0644`.

- Keep the source authoritative: chosen; normal apply prompts when the runtime target has drifted, and `--force` restores the source content and `0644` mode.
- Treat runtime edits as authoritative: rejected because they require a deliberate `chezmoi re-add` to update the canonical source and otherwise make applies diverge across machines.
- Ignore the target: rejected because it would stop managing the canonical settings file.

## Evidence and migration boundary

The official [umask configuration reference](https://www.chezmoi.io/reference/configuration-file/umask/) documents the configured mask. The [source state attributes reference](https://www.chezmoi.io/reference/source-state-attributes/) documents the `private_` and `executable_` modes. chezmoi v2.72.1's [source-state implementation](https://github.com/twpayne/chezmoi/blob/v2.72.1/internal/chezmoi/sourcestate.go) and [target directory implementation](https://github.com/twpayne/chezmoi/blob/v2.72.1/internal/chezmoi/targetstateentry.go#L163-L183) were also inspected, and a temporary-source reproduction confirmed that `dot_config` and `private_dot_config` collide at `.config`.

With chezmoi v2.72.1, a caller umask of `077` produced `0600` ordinary files and `0700` ordinary directories; configuring `umask: 18` normalized already-existing paths to `0644` and `0755`, while private entries remained `0600` and `0700`. This reproduces the reported mode pattern. The exited worker's exact historical umask was not present in the available logs, so `077` is a reproduced cause, not a directly recovered historical value.

There is one upstream first-creation limit: a fresh ordinary directory created under process umask `077` starts as `0700` on its first apply, then chezmoi corrects it to `0755` on a later apply. v2.72.1 calls `mkdir` for a new target directory and only applies `chmod` when the directory already exists. The configured mask normalizes existing entries in one apply; it does not change the caller process's OS umask for that initial `mkdir`.

The reported Mac leftovers were moved outside the source tree and the 16 affected home links were re-applied before this change, outside this repository diff. For remaining runtime-created files, apply stops until the explicit migration helper atomically moves each source entry into a retained backup on the same filesystem and the home target is verified. Backups remain under `~/.local/state/chezmoi-migration/` for manual recovery. No apply was run against the real home directory.
