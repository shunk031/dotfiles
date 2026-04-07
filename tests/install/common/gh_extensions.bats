#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/gh_extensions.sh"

@test "[common] gh_extensions" {
    source "${SCRIPT_PATH}"
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run gh extension list
    [ "$status" -eq 0 ]

    for ext in "${GH_EXTENSIONS[@]}"; do
        echo "$output" | grep -Fq "$ext"
    done
}
