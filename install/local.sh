#!/bin/bash

# cd "$(dirname "${BASH_SOURCE[0]}")" \
    #     && . "install/util.sh"

. "install/util.sh" || exit 1

create_secret() {
    declare -r EXAMPLE_FILE_PATH="${DOTPATH}/.secret.zsh.example"
    declare -r FILE_PATH="${DOTPATH}/.secret.zsh"

    if [ ! -f $FILE_PATH ]; then
        cp $EXAMPLE_FILE_PATH $FILE_PATH
    fi

    print_result $? "$FILE_PATH"
}

create_pypirc() {
    declare -r EXAMPLE_FILE_PATH="${DOTPATH}/.pypirc.example"
    declare -r FILE_PATH="${DOTPATH}/.pypirc"

    if [ ! -f $FILE_PATH ]; then
        cp $EXAMPLE_FILE_PATH $FILE_PATH
    fi

    print_result $? "$FILE_PATH"
}

setup_git_config() {
    declare -r GIT_CONFIG_DIR="${HOME}/.config/git"

    if [ ! -e $GIT_CONFIG_DIR ]; then
        declare -r GIT_IGNORE_SRC_PATH="${DOTPATH}/.gitignore_global"
        declare -r GIT_IGNORE_DST_PATH="${GIT_CONFIG_DIR}/ignore"

        mkdir -p $GIT_CONFIG_DIR
        ln -sfn $GIT_IGNORE_SRC_PATH $GIT_IGNORE_DST_PATH

        print_result $? "$GIT_IGNORE_DST_PATH"
    fi
}

main() {
    print_in_purple "\n • Create local config files\n\n"

    create_secret
    create_pypirc

    setup_git_config
}

main
