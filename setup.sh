#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck disable=SC2016
declare -r DOTFILES_LOGO='
                          /$$                                      /$$
                         | $$                                     | $$
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$
                                           | $$
                                           |__/

             *** This is setup script for my dotfiles setup ***            
                     https://github.com/shunk031/dotfiles
'

declare -r DOTFILES_REPO_URL="https://github.com/shunk031/dotfiles"

function at_exit() {
    AT_EXIT+="${AT_EXIT:+$'\n'}"
    AT_EXIT+="${*?}"
    # shellcheck disable=SC2064
    trap "${AT_EXIT}" EXIT
}

function get_os_type() {
    uname
}

function initialize_dotfiles() {
    function run_chezmoi() {
        # Detect whether `/dev/tty` is available
        # ref. https://stackoverflow.com/a/69088164
        local no_tty_option
        if sh -c ": >/dev/tty" >/dev/null 2>/dev/null; then
            no_tty_option="" # /dev/tty is available
        else
            no_tty_option="--no-tty" # /dev/tty is not available (especially in the CI)
        fi

        # run the chezmoi init command with/without the `--no-tty` option
        # chezmoi init has `--purge-binary` option to remove its own binary;
        # however this option will disturb testing by the CI because it displays prompt.
        sh -c "$(curl -fsLS get.chezmoi.io)" -- init "${DOTFILES_REPO_URL}" --apply ${no_tty_option} --use-builtin-git true
    }
    function cleanup_chezmoi() {
        # remove the chezmoi binary without prompt as described above.
        rm -f "${HOME}/bin/chezmoi"
    }

    run_chezmoi
    cleanup_chezmoi
}

function get_system_from_chezmoi() {
    local system
    system=$(chezmoi data | jq -r '.system')
    echo "${system}"
}

function restart_shell_system() {
    local system
    system=$(get_system_from_chezmoi)

    # exec shell as login shell (to reload the .zprofile or .profile)
    if [ "${system}" == "client" ]; then
        /bin/zsh --login

    elif [ "${system}" == "server" ]; then
        /bin/bash --login

    else
        echo "Invalid system: ${system}; expected \`client\` or \`server\`" >&2
        exit 1
    fi
}

function restart_shell() {

    # Restart shell if specified "bash -c $(curl -L {URL})"
    # not restart:
    #   curl -L {URL} | bash
    if [ -p /dev/stdin ]; then
        echo "Now continue with Rebooting your shell"
    else
        echo "Restarting your shell..."
        restart_shell_system
    fi
}

function main() {
    echo "$DOTFILES_LOGO"

    initialize_dotfiles

    # restart_shell # Disabled because the at_exit function does not work properly.
}

main "$@"
