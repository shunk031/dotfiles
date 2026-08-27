#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/skills.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_after_30-reconcile-agent-skills.sh.tmpl"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly GEMINI_SKILLS_CONFIG_PATH="./home/dot_gemini/config/skills.json"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin" "${HOME}/.agents/skills"

    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH

    source "${SCRIPT_PATH}"
}

function teardown() {
    PATH=$(getconf PATH)
    export PATH
}

# @description Install `mise` and `skills` stubs that record their arguments.
# @arg $1 exit_code The status the stub exits with; defaults to 0.
function write_mise_stub() {
    local exit_code="${1:-0}"
    local stub_bin="${BATS_TEST_TMPDIR}/bin"

    cat > "${MISE_BIN}" << EOF
#!/usr/bin/env bash
if [ "\$*" = "activate bash" ]; then
    printf 'export PATH="%s:\$PATH"\n' "${stub_bin}"
    exit 0
fi
printf '%s\n' "\$*" >> "\${MISE_CALLS_PATH}"
exit ${exit_code}
EOF
    chmod +x "${MISE_BIN}"

    mkdir -p "${stub_bin}"
    cat > "${stub_bin}/skills" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "\${MISE_CALLS_PATH}"
exit ${exit_code}
EOF
    chmod +x "${stub_bin}/skills"
    PATH="${stub_bin}:${PATH}"
    export PATH
}

@test "[common] skills CLI uses the active tool without re-entering mise" {
    write_mise_stub
    PATH="${PATH#"${BATS_TEST_TMPDIR}/bin:"}"
    export PATH

    activate_mise
    skills_cli --version

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--version" ]
}

@test "[common] skills reconcile template exists and runs after the mise tools script" {
    [ -f "${TMPL_SCRIPT_PATH}" ]

    # chezmoi orders `after` scripts by target name, and reconciliation needs
    # the pinned skills CLI that `run_after_20-install-mise-tools` installs.
    run bash -c "printf '%s\n' 20-install-mise-tools 30-reconcile-agent-skills | sort | head -n 1"
    [ "${output}" = "20-install-mise-tools" ]
}

@test "[common] every allowlist entry parses into a source and a skill" {
    [ "${#SKILLS_ALLOWLIST[@]}" -gt 0 ]

    for entry in "${SKILLS_ALLOWLIST[@]}"; do
        run allowlist_entry_source "${entry}"
        [ "${status}" -eq 0 ]
        [[ "${output}" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(#.+)?$ ]]

        run allowlist_entry_skill "${entry}"
        [ "${status}" -eq 0 ]
        [ -n "${output}" ]
        [[ "${output}" != *:* ]]
    done
}

@test "[common] the allowlist subscribes to the public skill repositories" {
    run allowlist_skill_names
    [ "${status}" -eq 0 ]

    printf '%s\n' "${SKILLS_ALLOWLIST[@]}" | grep -q '^shunk031/skills:'
    printf '%s\n' "${SKILLS_ALLOWLIST[@]}" | grep -q '^anthropics/skills:'
    printf '%s\n' "${SKILLS_ALLOWLIST[@]}" | grep -q '^cursor/plugins:unslop$'
    printf '%s\n' "${SKILLS_ALLOWLIST[@]}" | grep -q '^mattpocock/skills:grill-me$'
    printf '%s\n' "${SKILLS_ALLOWLIST[@]}" | grep -q '^mattpocock/skills:grilling$'
}

@test "[common] the allowlist holds no duplicate skill names" {
    local duplicates
    duplicates="$(allowlist_skill_names | sort | uniq -d)"
    [ -z "${duplicates}" ]
}

@test "[common] prune removes nothing when no manifest exists" {
    write_mise_stub
    mkdir -p "${SKILLS_POOL}/shunk031-retired"

    prune_unlisted_skills

    [ -d "${SKILLS_POOL}/shunk031-retired" ]
    [ ! -f "${MISE_CALLS_PATH}" ]
}

@test "[common] prune removes a manifest skill the allowlist dropped" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/shunk031-retired"
    printf '%s\n' shunk031-retired > "${SKILLS_MANIFEST}"

    prune_unlisted_skills

    [ ! -e "${SKILLS_POOL}/shunk031-retired" ]
}

@test "[common] prune unsubscribes a private skill once its allowlist is gone" {
    # Intended, not incidental. The private allowlist is the declaration, so an
    # absent file means no subscription, exactly as a removed public entry does.
    # It also keeps private skill content from outliving a machine's access to
    # the private source. Ordinary applies never reach this: `run_once_after_01`
    # applies the private source before `run_after_30` first reconciles.
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/private-example"
    printf '%s\n' private-example > "${SKILLS_MANIFEST}"
    [ ! -f "${SKILLS_PRIVATE_ALLOWLIST}" ]

    prune_unlisted_skills

    [ ! -e "${SKILLS_POOL}/private-example" ]
}

@test "[common] prune keeps a private skill while its allowlist declares it" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/private-example"
    mkdir -p "$(dirname -- "${SKILLS_PRIVATE_ALLOWLIST}")"
    printf '%s\n' private-example > "${SKILLS_MANIFEST}"
    printf 'owner/repo:private-example\n' > "${SKILLS_PRIVATE_ALLOWLIST}"

    prune_unlisted_skills

    [ -d "${SKILLS_POOL}/private-example" ]
    [ ! -f "${MISE_CALLS_PATH}" ]
}

@test "[common] prune scopes every removal to the owned agents" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/shunk031-retired"
    printf '%s\n' shunk031-retired > "${SKILLS_MANIFEST}"

    prune_unlisted_skills

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "remove --skill shunk031-retired --agent claude-code --agent codex --global --yes" ]
}

@test "[common] prune never targets the agents rooted at the private config tree" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/shunk031-retired"
    printf '%s\n' shunk031-retired > "${SKILLS_MANIFEST}"

    prune_unlisted_skills

    # An unscoped `skills remove` walks the CLI's whole agent registry, and
    # `amp` and `universal` resolve to `~/.config/agents/skills`, which the
    # private dotfiles own.
    run grep -c -E -- '--agent (amp|universal)' "${MISE_CALLS_PATH}"
    [ "${output}" = "0" ]
}

@test "[common] prune never removes an installer-generated pool entry" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${SKILLS_POOL}/herdr"
    printf '%s\n' herdr > "${SKILLS_MANIFEST}"

    prune_unlisted_skills

    [ -d "${SKILLS_POOL}/herdr" ]
    [ ! -f "${MISE_CALLS_PATH}" ]
}

@test "[common] prune leaves a legacy adapter symlink for chezmoi to own" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}" "${BATS_TEST_TMPDIR}/source/shunk031-retired"
    ln -s "${BATS_TEST_TMPDIR}/source/shunk031-retired" "${SKILLS_POOL}/shunk031-retired"
    printf '%s\n' shunk031-retired > "${SKILLS_MANIFEST}"

    prune_unlisted_skills

    [ -L "${SKILLS_POOL}/shunk031-retired" ]
    [ -d "${BATS_TEST_TMPDIR}/source/shunk031-retired" ]
}

@test "[common] install skips a skill already materialized in the pool" {
    write_mise_stub
    mkdir -p "${SKILLS_POOL}/shunk031-cgd-dev-identity"

    install_missing_skills

    run grep -c -- '--skill shunk031-cgd-dev-identity ' "${MISE_CALLS_PATH}"
    [ "${output}" = "0" ]
}

@test "[common] install replaces a legacy symlink with a real installation" {
    write_mise_stub
    mkdir -p "${BATS_TEST_TMPDIR}/source/shunk031-cgd-dev-identity"
    ln -s "${BATS_TEST_TMPDIR}/source/shunk031-cgd-dev-identity" "${SKILLS_POOL}/shunk031-cgd-dev-identity"

    install_missing_skills

    # The name still goes to the CLI: a symlink is not a real installation, so
    # `pool_has_skill` rejects it and the skill stays in the batch. The call now
    # carries every missing skill from that source rather than only this one.
    run grep -c -- '--skill shunk031-cgd-dev-identity' "${MISE_CALLS_PATH}"
    [ "${output}" = "1" ]

    run grep -c -- 'add shunk031/skills .*--agent claude-code --agent codex --global --yes' "${MISE_CALLS_PATH}"
    [ "${output}" = "1" ]
}

@test "[common] install issues one call per repository, not per skill" {
    # `skills add` takes --skill repeatably and clones the repository once per
    # call, so one call per skill re-clones the same repository for every entry.
    write_mise_stub

    install_missing_skills

    # Each distinct source should be cloned exactly once, with all of its
    # missing skills batched into that call.
    local expected_calls
    expected_calls="$(declared_sources | awk 'NF { count++ } END { print count + 0 }')"
    run grep -c '^add ' "${MISE_CALLS_PATH}"
    [ "${output}" -eq "${expected_calls}" ]

    run grep -c -- '--skill shunk031-cgd-dev-identity' "${MISE_CALLS_PATH}"
    [ "${output}" = "1" ]
    run grep -c -- '--skill shunk031-manage-agent-guidance' "${MISE_CALLS_PATH}"
    [ "${output}" = "1" ]
}

@test "[common] a repository is called with only the skills still missing" {
    write_mise_stub
    mkdir -p "${SKILLS_POOL}/shunk031-cgd-dev-identity"

    install_missing_skills

    run grep -c -- '--skill shunk031-cgd-dev-identity' "${MISE_CALLS_PATH}"
    [ "${output}" = "0" ]
    run grep -c -- '--skill shunk031-manage-agent-guidance' "${MISE_CALLS_PATH}"
    [ "${output}" = "1" ]
}

@test "[common] a repository with nothing missing is not called at all" {
    write_mise_stub
    local name
    while IFS= read -r name; do
        mkdir -p "${SKILLS_POOL}/${name}"
    done < <(allowlist_skill_names)

    install_missing_skills

    [ ! -f "${MISE_CALLS_PATH}" ]
}

@test "[common] a failing install is reported without aborting the apply" {
    write_mise_stub 1

    run install_missing_skills
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"could not be installed"* ]]
}

@test "[common] reconcile succeeds when every network call fails" {
    write_mise_stub 1

    run reconcile_agent_skills
    [ "${status}" -eq 0 ]
}

@test "[common] reconcile is skipped when mise is not installed" {
    rm -f "${MISE_BIN}"

    run reconcile_agent_skills
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"skipping reconciliation"* ]]
}

@test "[common] generated pool entries are linked into the agent directory" {
    mkdir -p "${SKILLS_POOL}/herdr"

    link_generated_pool_entries

    [ -L "${HOME}/.claude/skills/herdr" ]
    [ "$(readlink "${HOME}/.claude/skills/herdr")" = "${SKILLS_POOL}/herdr" ]
}

@test "[common] a real agent entry is never replaced by a pool link" {
    mkdir -p "${SKILLS_POOL}/herdr" "${HOME}/.claude/skills/herdr"
    printf '%s\n' 'installer owned' > "${HOME}/.claude/skills/herdr/SKILL.md"

    run link_generated_pool_entries
    [ "${status}" -eq 0 ]

    [ ! -L "${HOME}/.claude/skills/herdr" ]
    [ -f "${HOME}/.claude/skills/herdr/SKILL.md" ]
}

@test "[common] the manifest records only skills that are really installed" {
    mkdir -p "${SKILLS_POOL}/shunk031-cgd-dev-identity"
    mkdir -p "${BATS_TEST_TMPDIR}/source/shunk031-manage-agent-guidance"
    ln -s "${BATS_TEST_TMPDIR}/source/shunk031-manage-agent-guidance" "${SKILLS_POOL}/shunk031-manage-agent-guidance"

    write_managed_skills_manifest

    run grep -c '^shunk031-cgd-dev-identity$' "${SKILLS_MANIFEST}"
    [ "${output}" = "1" ]
    run grep -c '^shunk031-manage-agent-guidance$' "${SKILLS_MANIFEST}"
    [ "${output}" = "0" ]
}

@test "[common] the manifest lives outside the exact_ agents tree" {
    # `~/.agents` is applied with `exact_` semantics, so state written inside it
    # would be deleted on the next apply.
    [[ "${SKILLS_MANIFEST}" != "${HOME}/.agents/"* ]]
    [[ "${SKILLS_MANIFEST}" == "${HOME}/.local/state/dotfiles/"* ]]
}

@test "[common] a recent update stamp throttles the update" {
    mkdir -p "${SKILLS_STATE_DIR}"
    date +%s > "${SKILLS_UPDATE_STAMP}"

    run skills_update_is_due
    [ "${status}" -eq 1 ]
}

@test "[common] a stale update stamp allows the update" {
    mkdir -p "${SKILLS_STATE_DIR}"
    printf '%s\n' 1 > "${SKILLS_UPDATE_STAMP}"

    run skills_update_is_due
    [ "${status}" -eq 0 ]
}

@test "[common] a corrupt update stamp does not wedge updates" {
    mkdir -p "${SKILLS_STATE_DIR}"
    printf '%s\n' 'not-a-timestamp' > "${SKILLS_UPDATE_STAMP}"

    run skills_update_is_due
    [ "${status}" -eq 0 ]
}

@test "[common] the force override beats the throttle" {
    mkdir -p "${SKILLS_STATE_DIR}"
    date +%s > "${SKILLS_UPDATE_STAMP}"

    export DOTFILES_SKILLS_FORCE_UPDATE=1

    run skills_update_is_due
    [ "${status}" -eq 0 ]
}

@test "[common] a successful update refreshes the stamp" {
    write_mise_stub
    mkdir -p "${SKILLS_STATE_DIR}"
    printf '%s\n' 1 > "${SKILLS_UPDATE_STAMP}"

    update_installed_skills

    run cat "${SKILLS_UPDATE_STAMP}"
    [ "${output}" != "1" ]
}

@test "[common] a failed update leaves the stamp alone so the next apply retries" {
    write_mise_stub 1
    mkdir -p "${SKILLS_STATE_DIR}"
    printf '%s\n' 1 > "${SKILLS_UPDATE_STAMP}"

    run update_installed_skills
    [ "${status}" -eq 0 ]

    run cat "${SKILLS_UPDATE_STAMP}"
    [ "${output}" = "1" ]
}

@test "[common] the shared pool is ignored by chezmoi" {
    # `~/.agents` is applied with `exact_` semantics, so without this entry
    # chezmoi treats every pool directory the `skills` CLI installed as an
    # unmanaged stray and deletes it on the next apply.
    run grep -Fx '.agents/skills' "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] the skill lock file stays ignored by chezmoi" {
    # The CLI rewrites it on every add, remove, and update.
    run grep -Fx '.agents/.skill-lock.json' "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Antigravity reads the shared pool through one config entry" {
    [ -f "${GEMINI_SKILLS_CONFIG_PATH}" ]

    run grep -F '~/.agents/skills' "${GEMINI_SKILLS_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] the public allowlist names no private skill" {
    # This repository is public. A private skill's name is disclosure on its
    # own: it can carry an internal host, an internal service, or an internal
    # process. Private subscriptions belong in the file the private dotfiles
    # source applies, never in this one.
    run grep -c 'skills-private:' "${SCRIPT_PATH}"
    [ "${output}" = "0" ]
}

@test "[common] a missing private allowlist is not an error" {
    # A machine with only the public source has no private file, and must
    # reconcile the public skills normally rather than failing the apply.
    [ ! -f "${SKILLS_PRIVATE_ALLOWLIST}" ]

    run declared_subscriptions
    [ "${status}" -eq 0 ]
    [ -n "${output}" ]
}

@test "[common] private entries join the public ones when the file is applied" {
    mkdir -p "$(dirname -- "${SKILLS_PRIVATE_ALLOWLIST}")"
    printf 'owner/repo:private-example\n' > "${SKILLS_PRIVATE_ALLOWLIST}"

    run declared_subscriptions
    [ "${status}" -eq 0 ]
    printf '%s\n' "${output}" | grep -q '^owner/repo:private-example$'
    printf '%s\n' "${output}" | grep -q '^shunk031/skills:'
}

@test "[common] a private entry keeps its pinned ref through comment stripping" {
    # Entries may carry a `#<ref>` suffix pinning a branch or tag. Stripping
    # from any `#` would rewrite such an entry to an unpinned one, which still
    # parses and still installs — just from a revision nobody declared.
    mkdir -p "$(dirname -- "${SKILLS_PRIVATE_ALLOWLIST}")"
    printf '# a whole-line comment\n\nowner/repo#some-branch:pinned-example\n' \
        > "${SKILLS_PRIVATE_ALLOWLIST}"

    run declared_subscriptions
    [ "${status}" -eq 0 ]
    printf '%s\n' "${output}" | grep -q '^owner/repo#some-branch:pinned-example$'
    ! printf '%s\n' "${output}" | grep -q '^#'
}
