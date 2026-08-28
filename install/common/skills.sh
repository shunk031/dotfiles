#!/usr/bin/env bash

# @file install/common/skills.sh
# @brief Reconcile the shared skills pool against a declared allowlist.
# @description
#   Skill content lives in `shunk031/skills` and `shunk031/skills-private`.
#   These dotfiles subscribe to those repositories rather than carrying the
#   skills themselves: `SKILLS_ALLOWLIST` declares what should be installed,
#   and `reconcile_agent_skills` makes `~/.agents/skills` match it on every
#   `chezmoi apply`.
#
#   Reconciliation is install, update, and prune. It is written to be safe to
#   run on every apply, which means it must be quiet when nothing changed and
#   must never remove an entry it did not install:
#
#   * Install skips names already materialized in the pool, so a steady-state
#     apply performs no network access.
#   * Update runs on a 24-hour stamp because `make watch` applies on every file
#     save. `DOTFILES_SKILLS_FORCE_UPDATE=1` overrides the throttle.
#   * Prune consults a manifest of what the previous run installed. Without
#     that manifest it removes nothing, because "everything not in the
#     allowlist" would delete the private skills and the generated `herdr`
#     entry.
#
#   A failed install is reported and does not abort the apply. Losing one skill
#   is better than failing the whole apply, and the next reconcile retries.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly SKILLS_POOL="${HOME}/.agents/skills"
readonly SKILLS_STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
# The manifest deliberately lives outside `~/.agents`. That tree is applied
# with `exact_` semantics, so a state file written inside it would be deleted
# on the next apply unless it also earned a chezmoiignore entry.
readonly SKILLS_MANIFEST="${SKILLS_STATE_DIR}/managed-skills"
readonly SKILLS_UPDATE_STAMP="${SKILLS_STATE_DIR}/skills-update-stamp"
readonly SKILLS_UPDATE_INTERVAL_SECONDS=86400

# Scope every CLI call to the agents these dotfiles own. This is not cosmetic:
# an unscoped `skills remove` targets every agent in the CLI's registry, and
# that registry maps `amp` and `universal` to `~/.config/agents/skills`, which
# the private dotfiles manage. Codex is a "universal" agent, so its skills are
# served from `~/.agents/skills` directly and no `~/.codex/skills` is created.
readonly SKILLS_AGENT_FLAGS=(
    --agent claude-code
    --agent codex
)

# Pool entries written by an installer rather than by the skills CLI. The CLI
# only links what it installed, so these need their own per-agent links.
readonly SKILLS_GENERATED_ENTRIES=(
    herdr
)

readonly SKILLS_RETIRED_NAMES=(
    shunk031-cgd-dev-identity
    shunk031-gh-comment-attach-files
    shunk031-high-impact-journal-publishing
    shunk031-orchestrate-herdr-workers
    shunk031-shdoc-shell-docs
    shunk031-transformers-convert
)

# Agent skills directories that are fed by symlinks into the pool. Codex is
# absent on purpose: it reads the pool itself.
readonly SKILLS_LINKED_AGENT_DIRS=(
    "${HOME}/.claude/skills"
)

# Declared subscriptions, one skill per line, as `<owner>/<repo>[#<ref>]:<skill>`.
# Keep sorted by repository, then by skill name.
readonly SKILLS_ALLOWLIST=(
    "anthropics/skills:skill-creator"
    "coji/natural-japanese:natural-japanese"
    "cursor/plugins:unslop"
    "mattpocock/skills:grilling"
    "shunk031/skills:shunk031-codex-worker-prompting"
    "shunk031/skills:shunk031-github-cgd-identity"
    "shunk031/skills:shunk031-github-comment-attach-files"
    "shunk031/skills:shunk031-herdr-orchestrate-workers"
    "shunk031/skills:shunk031-herdr-tab-status"
    "shunk031/skills:shunk031-manage-agent-guidance"
    "shunk031/skills:shunk031-manage-public-private-dotfiles"
    "shunk031/skills:shunk031-manage-public-private-skills"
    "shunk031/skills:shunk031-python-transformers-convert"
    "shunk031/skills:shunk031-python-uv-workflow"
    "shunk031/skills:shunk031-research-before-implementation"
    "shunk031/skills:shunk031-research-high-impact-journal-publishing"
    "shunk031/skills:shunk031-shellscript-shdoc-docs"
)

# Private subscriptions, applied by the private dotfiles source. Absent on a
# machine that has only the public source, in which case only public skills are
# reconciled and nothing else changes.
readonly SKILLS_PRIVATE_ALLOWLIST="${HOME}/.config/agents/skills-private.allowlist"

#
# @description Read lines from standard input into a named array.
# @description
#   `mapfile` is Bash 4 only and macOS ships Bash 3.2.
# @arg $1 array_name string The array to replace with the lines read.
#
function read_lines_into() {
    local array_name="$1"
    local line
    eval "${array_name}=()"
    while IFS= read -r line; do
        [ -n "${line}" ] || continue
        eval "${array_name}+=(\"\${line}\")"
    done
}

#
# @description Print every declared subscription, public and private.
# @description
#   The private entries are read at runtime rather than committed here, because
#   this repository is public and a private skill's name is disclosure on its
#   own. A missing file is normal, not an error.
# @stdout One `<owner>/<repo>[#<ref>]:<skill>` entry per line.
#
function declared_subscriptions() {
    if [ "${#SKILLS_ALLOWLIST[@]}" -gt 0 ]; then
        printf '%s\n' "${SKILLS_ALLOWLIST[@]}"
    fi
    if [ -f "${SKILLS_PRIVATE_ALLOWLIST}" ]; then
        # Drop whole-line comments and blank lines so the private file can
        # explain itself. Only a leading `#` starts a comment: an entry may
        # carry a `#<ref>` suffix pinning a branch or tag, and stripping from
        # any `#` would silently rewrite such an entry to an unpinned one.
        sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "${SKILLS_PRIVATE_ALLOWLIST}"
    fi
}

#
# @description Activate `mise` so the pinned `skills` CLI resolves.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Run the pinned `skills` CLI.
# @description
#   The CLI's GitHub tree check uses Node's `fetch`, which does not use
#   `HTTP_PROXY` or `HTTPS_PROXY` unless `NODE_USE_ENV_PROXY=1` is set. In a
#   proxied environment, force a fresh reconciliation with:
#   `NODE_USE_ENV_PROXY=1 DOTFILES_SKILLS_FORCE_UPDATE=1 chezmoi apply`
# @arg $@ string Arguments forwarded to the CLI.
#
function skills_cli() {
    skills "$@"
}

#
# @description Export a GitHub token so the private repository can be cloned.
# @description
#   The clone itself authenticates through git's credential helper. This export
#   only covers hosts where the helper is not configured yet, which is the case
#   part-way through a first bootstrap. A missing token is not fatal: the
#   private source simply fails to clone and the failure is reported.
#
function export_github_token() {
    if [ -n "${GH_TOKEN:-}" ]; then
        return 0
    fi
    if ! command -v gh > /dev/null 2>&1; then
        return 0
    fi
    if GH_TOKEN="$(gh auth token 2> /dev/null)" && [ -n "${GH_TOKEN}" ]; then
        export GH_TOKEN
    else
        unset GH_TOKEN
    fi
}

#
# @description Print the source repository of an allowlist entry.
# @arg $1 entry string An `<owner>/<repo>[#<ref>]:<skill>` entry.
# @stdout The source repository, including any `#<ref>` suffix.
#
function allowlist_entry_source() {
    printf '%s\n' "${1%:*}"
}

#
# @description Print the skill name of an allowlist entry.
# @arg $1 entry string An `<owner>/<repo>[#<ref>]:<skill>` entry.
# @stdout The skill name.
#
function allowlist_entry_skill() {
    printf '%s\n' "${1##*:}"
}

#
# @description Print every source a subscription installs from.
# @description
#   Deduplicated, because `skills add` clones the repository it is given. One
#   call per skill re-clones the same repository for every entry it holds.
# @stdout Newline-separated `<owner>/<repo>[#<ref>]`, sorted and unique.
#
function declared_sources() {
    local entry

    local -a subscriptions=()
    read_lines_into subscriptions < <(declared_subscriptions)
    if [ "${#subscriptions[@]}" -eq 0 ]; then
        return 0
    fi

    for entry in "${subscriptions[@]}"; do
        allowlist_entry_source "${entry}"
    done | LC_ALL=C sort -u
}

#
# @description Print `--skill <name>` flags for one source's missing skills.
# @description
#   `skills add` takes `--skill` repeatably, so a source installs in one call.
#   A source with nothing missing yields nothing, and the caller skips it, which
#   is what keeps a steady-state apply off the network.
# @arg $1 source string An `<owner>/<repo>[#<ref>]`.
# @stdout Alternating `--skill` and skill-name lines, or nothing.
#
function missing_skill_flags() {
    local source="$1"
    local entry skill

    local -a subscriptions=()
    read_lines_into subscriptions < <(declared_subscriptions)
    if [ "${#subscriptions[@]}" -eq 0 ]; then
        return 0
    fi

    for entry in "${subscriptions[@]}"; do
        [ "$(allowlist_entry_source "${entry}")" = "${source}" ] || continue

        skill="$(allowlist_entry_skill "${entry}")"
        if pool_has_skill "${skill}"; then
            continue
        fi

        printf -- '--skill\n%s\n' "${skill}"
    done
}

#
# @description Print every skill name in the allowlist, one per line.
# @stdout Newline-separated skill names.
#
function allowlist_skill_names() {
    local entry

    # Bash 3.2 with `set -u` aborts on an empty array expansion.
    local -a subscriptions=()
    read_lines_into subscriptions < <(declared_subscriptions)
    if [ "${#subscriptions[@]}" -eq 0 ]; then
        return 0
    fi

    for entry in "${subscriptions[@]}"; do
        allowlist_entry_skill "${entry}"
    done
}

#
# @description Test whether a pool entry is written by an installer.
# @description
#   Prune must never touch these. Today they cannot reach the manifest, but
#   that is an accident of how the manifest is built, and this is a `rm -rf`.
#   The guarantee belongs next to the deletion, not in the caller.
# @arg $1 name string The pool entry name.
# @exitcode 0 When the entry is installer-generated.
# @exitcode 1 When it is not.
#
function is_generated_pool_entry() {
    local name="$1"
    local generated

    if [ "${#SKILLS_GENERATED_ENTRIES[@]}" -eq 0 ]; then
        return 1
    fi

    for generated in "${SKILLS_GENERATED_ENTRIES[@]}"; do
        if [ "${generated}" = "${name}" ]; then
            return 0
        fi
    done

    return 1
}

#
# @description Test whether a skill name is declared in the allowlist.
# @arg $1 name string The skill name.
# @exitcode 0 When the name is declared.
# @exitcode 1 When it is not.
#
function allowlist_contains() {
    local name="$1"
    local entry

    local -a subscriptions=()
    read_lines_into subscriptions < <(declared_subscriptions)
    if [ "${#subscriptions[@]}" -eq 0 ]; then
        return 1
    fi

    for entry in "${subscriptions[@]}"; do
        if [ "$(allowlist_entry_skill "${entry}")" = "${name}" ]; then
            return 0
        fi
    done

    return 1
}

#
# @description Test whether the CLI has materialized a skill in the pool.
# @description
#   A symlink does not count. During the migration a pool entry may still be a
#   legacy adapter pointing into a chezmoi source tree, and that has to be
#   replaced by a real installation rather than mistaken for one.
# @arg $1 name string The skill name.
# @exitcode 0 When a real directory exists for the skill.
# @exitcode 1 Otherwise.
#
function pool_has_skill() {
    local entry="${SKILLS_POOL}/$1"

    if [ -L "${entry}" ]; then
        return 1
    fi

    [ -d "${entry}" ]
}

#
# @description Install every allowlisted skill that is not already in the pool.
# @description
#   One call per source, not per skill. `skills add` clones the repository it is
#   given, so calling it per skill re-clones the same repository for every entry
#   it holds. Batching each source's skills into one call avoids that duplicate
#   cloning while preserving the source-level failure boundary.
#
#   Batching does not coarsen failure. A name the repository does not have is
#   skipped and the rest still install, with a zero exit; and a clone that fails
#   outright would have failed for every skill of that source anyway, because
#   each per-skill call cloned it too.
#
#   The same skipping means a typo in the allowlist is silent. The name simply
#   never arrives, and every apply retries it.
#
#   `skills add` replaces a legacy symlink with a real directory without
#   following it, so no separate cleanup step is needed. Leaving the symlink in
#   place until the install succeeds is also what keeps an offline apply
#   harmless: the old adapter keeps working.
# @exitcode 0 Always; individual failures are reported and counted.
#
function install_missing_skills() {
    local source
    local failures=0

    local -a sources=()
    read_lines_into sources < <(declared_sources)
    if [ "${#sources[@]}" -eq 0 ]; then
        return 0
    fi

    for source in "${sources[@]}"; do
        local -a flags=()
        read_lines_into flags < <(missing_skill_flags "${source}")
        if [ "${#flags[@]}" -eq 0 ]; then
            continue
        fi

        if ! skills_cli add "${source}" \
            "${flags[@]}" \
            "${SKILLS_AGENT_FLAGS[@]}" \
            --global \
            --yes; then
            echo "skills: failed to install from ${source}" >&2
            failures=$((failures + 1))
        fi
    done

    if [ "${failures}" -gt 0 ]; then
        echo "skills: ${failures} repository/repositories could not be installed; the next apply retries" >&2
    fi
}

#
# @description Test whether the throttled update window has elapsed.
# @exitcode 0 When an update should run.
# @exitcode 1 When the previous update is still recent.
#
function skills_update_is_due() {
    local stamp now

    if [ "${DOTFILES_SKILLS_FORCE_UPDATE:-}" = "1" ]; then
        return 0
    fi

    if [ ! -f "${SKILLS_UPDATE_STAMP}" ]; then
        return 0
    fi

    stamp="$(cat "${SKILLS_UPDATE_STAMP}" 2> /dev/null || true)"
    case "${stamp}" in
    '' | *[!0-9]*)
        # An unreadable or corrupt stamp should not wedge updates forever.
        return 0
        ;;
    esac

    now="$(date +%s)"
    [ "$((now - stamp))" -ge "${SKILLS_UPDATE_INTERVAL_SECONDS}" ]
}

#
# @description Update installed skills at most once per day.
# @exitcode 0 Always; a failed update is reported and retried later.
#
function update_installed_skills() {
    if ! skills_update_is_due; then
        return 0
    fi

    if ! skills_cli update --global --yes; then
        echo "skills: update failed; the next apply retries" >&2
        return 0
    fi

    mkdir -p "${SKILLS_STATE_DIR}"
    date +%s > "${SKILLS_UPDATE_STAMP}"
}

#
# @description Remove a pool entry this script installed.
# @description
#   `skills remove` cannot be relied on to clear the canonical directory. It
#   keeps that directory whenever any other detected agent still resolves to
#   it, and every "universal" agent resolves to exactly this path, so the
#   mere presence of `~/.gemini` is enough to make the removal a silent no-op.
#   A symlink is never removed here: that is a legacy adapter, not ours.
# @arg $1 name string The skill name.
#
function remove_pool_entry() {
    local entry="${SKILLS_POOL}/$1"

    if [ -L "${entry}" ]; then
        return 0
    fi

    if [ -d "${entry}" ]; then
        rm -rf "${entry}"
    fi
}

#
# @description Print managed skill names that may need pruning.
# @description
#   The manifest normally identifies removed subscriptions. Retired names are
#   also included while their old pool directory remains, because an earlier
#   reconciliation may already have replaced the manifest with the new name.
# @stdout Newline-separated skill names, sorted and unique.
#
function prune_candidate_names() {
    local name

    {
        if [ -f "${SKILLS_MANIFEST}" ]; then
            cat "${SKILLS_MANIFEST}"
        fi

        for name in "${SKILLS_RETIRED_NAMES[@]}"; do
            if pool_has_skill "${name}"; then
                printf '%s\n' "${name}"
            fi
        done
    } | LC_ALL=C sort -u
}

#
# @description Remove skills that the previous run installed and the allowlist
#   no longer declares.
# @description
#   Candidates are limited to the previous manifest and the explicit retired
#   name migration list. Pruning "everything in the pool that is not
#   allowlisted" would delete the generated `herdr` entry and any skill a
#   different installer owns.
#
#   An absent private allowlist unsubscribes its skills, and that is the
#   intended behaviour rather than an oversight. The file is the declaration:
#   no declaration means no subscription, which is exactly how a removed public
#   entry behaves. It is also the posture the public/private split exists for,
#   since private skill content should not outlive a machine's access to the
#   private source.
#
#   Ordinary applies never hit that path. `run_once_after_01` applies the
#   private source, and chezmoi orders `after` scripts by target name, so the
#   file is on disk before `run_after_30` first reconciles. `make watch`
#   applies only the public source, but by then the file is already there. The
#   only way to reach this case is for the private source to be gone or to have
#   failed to apply, and then removal is the correct answer.
#
function prune_unlisted_skills() {
    local name

    while IFS= read -r name || [ -n "${name}" ]; do
        if [ -z "${name}" ] ||
            allowlist_contains "${name}" ||
            is_generated_pool_entry "${name}"; then
            continue
        fi

        if ! skills_cli remove \
            --skill "${name}" \
            "${SKILLS_AGENT_FLAGS[@]}" \
            --global \
            --yes; then
            echo "skills: could not unregister ${name}" >&2
        fi

        remove_pool_entry "${name}"
    done < <(prune_candidate_names)
}

#
# @description Link pool entries that no skills CLI install created.
# @description
#   `install/common/herdr.sh` writes `~/.agents/skills/herdr/SKILL.md` straight
#   into the pool from the installed binary, so the CLI never learns about it
#   and never links it. A real entry already present in an agent directory is
#   left alone.
#
function link_generated_pool_entries() {
    local name entry agent_dir target

    if [ "${#SKILLS_GENERATED_ENTRIES[@]}" -eq 0 ] ||
        [ "${#SKILLS_LINKED_AGENT_DIRS[@]}" -eq 0 ]; then
        return 0
    fi

    for name in "${SKILLS_GENERATED_ENTRIES[@]}"; do
        entry="${SKILLS_POOL}/${name}"
        [ -d "${entry}" ] || continue

        for agent_dir in "${SKILLS_LINKED_AGENT_DIRS[@]}"; do
            mkdir -p "${agent_dir}"
            target="${agent_dir}/${name}"

            if [ -e "${target}" ] && [ ! -L "${target}" ]; then
                echo "skills: ${target} is a real entry, keeping it" >&2
                continue
            fi

            ln -sfn "${entry}" "${target}"
        done
    done
}

#
# @description Record the allowlisted skills that are present in the pool.
# @description
#   Only what is actually installed is recorded, so a skill that failed to
#   install is retried next time instead of being pruned later.
#
function write_managed_skills_manifest() {
    local name temp

    mkdir -p "${SKILLS_STATE_DIR}"
    temp="$(mktemp "${SKILLS_MANIFEST}.XXXXXX")" || return 1

    while IFS= read -r name; do
        if pool_has_skill "${name}"; then
            printf '%s\n' "${name}"
        fi
    done < <(allowlist_skill_names) > "${temp}"

    mv "${temp}" "${SKILLS_MANIFEST}"
}

#
# @description Make the shared skills pool match the declared allowlist.
#
function reconcile_agent_skills() {
    if [ ! -x "${MISE_BIN}" ]; then
        echo "skills: ${MISE_BIN} is not executable, skipping reconciliation" >&2
        return 0
    fi

    # Refuse to run unscoped. Without `--agent` flags the CLI targets every
    # agent it knows, including the ones rooted at `~/.config/agents/skills`.
    if [ "${#SKILLS_AGENT_FLAGS[@]}" -eq 0 ]; then
        echo "skills: no agents configured, refusing to reconcile" >&2
        return 1
    fi

    export_github_token
    prune_unlisted_skills
    install_missing_skills
    update_installed_skills
    link_generated_pool_entries
    write_managed_skills_manifest
}

#
# @description Run the skills reconciliation workflow.
#
function main() {
    activate_mise
    reconcile_agent_skills
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
