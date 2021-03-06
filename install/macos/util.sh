#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

brew_install() {
    declare -r CASK="$4"
    declare -r CMD_ARGUMENTS="$5"
    declare -r FORMULA="$2"
    declare -r FORMULA_READABLE_NAME="$1"
    declare -r TAP_VALUE="$3"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Check if `Homebrew` is installed.

    if ! cmd_exists "brew"; then
        print_error "$FORMULA_READABLE_NAME ('Homebrew' is not installed)"
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If `brew tap` needs to be executed,
    # check if it executed correctly.

    if [ -n "$TAP_VALUE" ]; then
        if ! brew_tap "$TAP_VALUE"; then
            print_error "$FORMULA_READABLE_NAME ('brew tap $TAP_VALUE' failed)"
            return 1
        fi
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Install the specified formula.

    # shellcheck disable=SC2086
    if brew $CMD list "$FORMULA" &> /dev/null; then
        print_success "$FORMULA_READABLE_NAME"
    elif [ -n "$CASK" ]; then
        execute \
            "brew install --cask $FORMULA $CMD_ARGUMENTS" \
            "$FORMULA_READABLE_NAME"
    else
        execute \
            "brew install $CMD $FORMULA $CMD_ARGUMENTS" \
            "$FORMULA_READABLE_NAME"
    fi
}

brew_prefix() {
    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if path="$(brew --prefix 2> /dev/null)"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get prefix)"
        return 1
    fi

}

brew_tap() {
    brew tap "$1" &> /dev/null
}

brew_update() {
    # if in the workflow, then not execute
    if [[ -z "$GITHUB_ACTIONS" ]]; then
        execute \
            "brew update" \
            "Homebrew (update)"
    else
        print_success "Homebrew (update)"
    fi
}

brew_upgrade() {
    # if in the workflow, then not execute
    if [[ -z "$GITHUB_ACTIONS" ]]; then
        execute \
            "brew upgrade" \
            "Homebrew (upgrade)"
    else
        print_success "Homebrew (upgrade)"
    fi
}
