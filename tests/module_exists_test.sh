#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

function test_module_exists() {
    local modules=(
        # for zplugin
        "${HOME}/.zplugin/bin"
        # for prezto
        "${ZDOTDIR:-$HOME}/.zprezto"
        # for docker completion in prezto
        "${HOME}/.zprezto/modules/completion/external/src"
        # for powerlevel9k
        "${HOME}/.zprezto/modules/prompt/external/powerlevel9k"
        # for pyenv
        "${HOME}/.pyenv"
        # for rbenv
        "${HOME}/.rbenv"
        # for goenv
        "${HOME}/.goenv"
        # for emacs.d (spacemacs)
        "${HOME}/.emacs.d"
    )
    
    for module in "${modules[@]}"
    do
        if [ ! -e "$module" ]; then
            echo "$module does not exists."
            exit 1
        fi
    done
    print_result $? "Done \`test_module_exists\`"
}

test_module_exists