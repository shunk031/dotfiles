#!/usr/bin/env bash

# @file install/ubuntu/server/setup_locale.sh
# @brief Ensure the preferred locale exists on Ubuntu servers.
# @description
#   Generates `en_US.UTF-8` when it is missing and updates the system locale
#   configuration.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TARGET="en_US.UTF-8"

#
# @description Generate the target locale when the server does not have it yet.
#
function main() {
    # `locale -a` often outputs in lowercase, so we convert to lowercase for comparison
    TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

    if ! locale -a 2> /dev/null | tr '[:upper:]' '[:lower:]' | grep -qx "$TARGET_LOWER"; then
        echo "Generating $TARGET ..."

        sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y locales
        sudo locale-gen "$TARGET" && sudo update-locale LANG="$TARGET"
    else
        echo "$TARGET already exists."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
