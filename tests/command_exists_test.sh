#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

function test_command_exists() {
    
    # restart the zsh
    exec "${SHELL:-$(command -v zsh)}"

    local cmds=(
        "git"
        "fzf"
    )
    for cmd in "${cmds[@]}"
    do
        if ! cmd_exists "$cmd"; then
            echo "$cmd does not exists."
            exit 1
        fi
    done
    print_result $? "Done \`test_command_exists\`"
}

test_command_exists
