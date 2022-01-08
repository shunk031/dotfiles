#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

function test_command_exists() {
    
    local cmds=(
        "fzf"
    )
    for cmd in "${cmds[@]}"
    do
        if ! cmd_exists "$cmd"; then
            echo "$cmd does not exists."
            command -v "$cmd"
            exit 1
        fi
    done
    print_result $? "Done \`test_command_exists\`"
}

test_command_exists
