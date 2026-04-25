#!/usr/bin/env bash

# @file home/dot_config/shell/npm-guard.sh
# @brief Block global npm install flows and direct package management to mise.
# @description
#   Defines an interactive-shell wrapper around `npm` that rejects global
#   install/update commands and points operators to `mise install "npm:<pkg>"`
#   and `mise upgrade npm:<pkg>` instead.

#
# @description Return success when the npm arguments describe a blocked global mutation.
#
function npm_guard_should_block() {
    local has_global="false"
    local subcommand=""

    while (($#)); do
        case "$1" in
        -g | --global | --location=global)
            has_global="true"
            ;;
        --location)
            shift
            if (($#)) && [[ "$1" == "global" ]]; then
                has_global="true"
            fi
            ;;
        -*)
            ;;
        *)
            if [[ -z "${subcommand}" ]]; then
                subcommand="$1"
            fi
            ;;
        esac
        shift
    done

    if [[ "${has_global}" != "true" ]]; then
        return 1
    fi

    case "${subcommand}" in
    install | i | add | update | upgrade)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

#
# @description Print the recommended mise-based replacement for blocked npm usage.
#
function npm_guard_print_message() {
    printf '%s\n' 'npm global install/update is blocked. Use mise-managed npm packages instead.' >&2
    printf '%s\n' '  Install: mise install "npm:<package>"' >&2
    printf '%s\n' '  Upgrade: mise upgrade npm:<package>' >&2
}

#
# @description Wrap npm and block global install flows in interactive shells.
#
function npm() {
    if [[ "$-" != *i* ]]; then
        command npm "$@"
        return
    fi

    if npm_guard_should_block "$@"; then
        npm_guard_print_message
        return 1
    fi

    command npm "$@"
}
