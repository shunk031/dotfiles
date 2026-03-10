#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TARGET="en_US.UTF-8"

function main() {
    # `locale -a` often outputs in lowercase, so we convert to lowercase for comparison
    TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

    if ! locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -qx "$TARGET_LOWER"; then
        echo "Generating $TARGET ..."

        sudo apt-get update &&
            sudo apt-get install -y locales &&
            sudo locale-gen "$TARGET" &&
            sudo update-locale LANG="$TARGET"
    else
        echo "$TARGET already exists."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
