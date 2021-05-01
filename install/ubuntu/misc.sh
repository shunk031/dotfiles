#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" |   # Get latest release from GitHub api
        grep '"tag_name":' |                                            # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

install_hadolint() {

    latest_relaase=$(get_latest_release "hadolint/hadolint")

    declare -r HADOLINT_DIR="${DOTPATH}/bin"
    declare -r HADOLINT_URL="https://github.com/hadolint/hadolint/releases/download/${latest_relaase}/hadolint-$(uname -s)-$(uname -m)"

    execute \
        "curl -sL -o ${HADOLINT_DIR}/hadolint ${HADOLINT_URL} \
              && chmod 700 ${HADOLINT_DIR}/hadolint" \
        "Install hadolint" \
        || return 1
}

print_in_purple "\n   Miscellaneous\n\n"

install_package "shellcheck" "shellcheck"
install_package "exa" "exa"

install_hadolint
