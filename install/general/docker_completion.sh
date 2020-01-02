#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_docker_completion() {
    declare -r DOCKER_COMPLETION_DIR="${HOME}/.zprezto/modules/completion/external/src"
    declare -r DOCKER_COMPLETION_URL="https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"

    execute \
        "curl -fLo ${DOCKER_COMPLETION_DIR}/_docker ${DOCKER_COMPLETION_URL}" \
        "Download to ${DOCKER_COMPLETION_DIR}" \
        || return 1
}

main() {
    print_in_purple "\n   Completion for docker commands\n\n"
    install_docker_completion
}

main
