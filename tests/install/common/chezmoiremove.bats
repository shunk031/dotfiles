#!/usr/bin/env bats

# `.chezmoiremove` names targets chezmoi should delete. If the source tree still
# holds the same path, chezmoi is told to create and to delete one entry and
# refuses the whole apply:
#
#   chezmoi: .config/agents/skills/<name>: inconsistent state (…, remove)
#
# It aborts before anything else in that run, so one leftover stops every other
# change too. This happened in the private source: a skill's tracked files were
# deleted, but an untracked `__pycache__` kept its directory alive, and the
# entire apply stopped there.
#
# Untracked files are what makes it easy to miss. `git status` says clean, the
# pull request diff says the skill is gone, and only chezmoi disagrees.

readonly CHEZMOIREMOVE_PATH="./home/.chezmoiremove"
readonly SOURCE_ROOT="./home"

# @description Print each removal target, skipping comments and blank lines.
# @stdout One target path per line.
function removal_targets() {
    sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "${CHEZMOIREMOVE_PATH}"
}

# @description Resolve a target path to its source path, if one exists.
# @description
#   chezmoi encodes a leading dot as `dot_` and may prefix a name with an
#   attribute such as `exact_` or `private_`. Both are stripped for the
#   comparison so a renamed attribute cannot hide a leftover.
# @arg $1 target string A path as written in `.chezmoiremove`.
# @stdout The source path when the target still exists in the source tree.
function source_path_for() {
    local target="$1"
    local base="${SOURCE_ROOT}"
    local segment candidate name matched

    local first=1
    local IFS='/'
    for segment in ${target}; do
        if [ "${first}" -eq 1 ]; then
            case "${segment}" in
            .*) segment="dot_${segment#.}" ;;
            esac
            first=0
        fi

        matched=''
        for candidate in "${base}"/*; do
            [ -e "${candidate}" ] || continue
            name="$(basename -- "${candidate}")"
            name="${name#exact_}"
            name="${name#private_}"
            name="${name#readonly_}"
            name="${name#encrypted_}"
            name="${name#symlink_}"
            name="${name%.tmpl}"
            if [ "${name}" = "${segment}" ]; then
                matched="${candidate}"
                break
            fi
        done

        [ -n "${matched}" ] || return 1
        base="${matched}"
    done

    printf '%s\n' "${base}"
}

@test "[common] every removal target is gone from the source tree" {
    local target source
    local -a leftovers=()

    while IFS= read -r target; do
        [ -n "${target}" ] || continue
        if source="$(source_path_for "${target}")"; then
            leftovers+=("${target} -> ${source}")
        fi
    done < <(removal_targets)

    if [ "${#leftovers[@]}" -gt 0 ]; then
        printf 'source still holds a path .chezmoiremove deletes:\n' >&3
        printf '  %s\n' "${leftovers[@]}" >&3
        printf 'chezmoi refuses the whole apply on this. Check for untracked\n' >&3
        printf 'leftovers such as __pycache__ that git does not report.\n' >&3
        return 1
    fi
}

@test "[common] the resolver finds a leftover that git would not report" {
    # Proves the check can fail. A directory kept alive by an untracked file is
    # the shape that stopped a real apply, and `git status` reports nothing.
    local probe="${SOURCE_ROOT}/dot_config/leftover-probe/scripts/__pycache__"
    mkdir -p "${probe}"
    printf 'bytecode\n' > "${probe}/module.cpython-314.pyc"

    run source_path_for ".config/leftover-probe"
    local status_seen="${status}"
    rm -rf "${SOURCE_ROOT}/dot_config/leftover-probe"

    [ "${status_seen}" -eq 0 ]
}
