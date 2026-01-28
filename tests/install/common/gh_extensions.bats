#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/gh_extensions.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[common] gh_extensions" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run gh extension list
    [ "$status" -eq 0 ]

    for ext in $GH_EXTENSIONS; do
        echo "$output" | grep -q "^$ext\s"
    done
}
