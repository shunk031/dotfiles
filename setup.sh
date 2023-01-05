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

function install_xcode() {

    local git_cmd_path="/Library/Developer/CommandLineTools/usr/bin/git"

    if [ ! -e "${git_cmd_path}" ]; then
        # Install command line developer tool
        xcode-select --install
        # Want for user input
        echo "Press any key when the installation has completed."
        IFS= read -r -n 1 -d ''
        #          │  │    └ The first character of DELIM is used to terminate the input line, rather than newline.
        #          │  └ returns after reading NCHARS characters rather than waiting for a complete line of input.
        #          └ If this option is given, backslash does not act as an escape character. The backslash is considered to be part of the line. In particular, a backslash-newline pair may not be used as a line continuation.
    else
        echo "Command line developer tools are installed."
    fi
}

function initialize_macos() {
    install_xcode
    echo "Finish to pre-initialize MacOS"
}

function initialize_linux() {
    echo "Finish to pre-initialize Linux OS"
}

function initialize_os_env() {
    local ostype
    ostype="$(uname)"

    if [ "${ostype}" == "Darwin" ]; then
        initialize_macos
    elif [ "${ostype}" == "Linux" ]; then
        initialize_linux
    else
        echo "Invalid OS type: ${ostype}"
        exit 1
    fi
}

function initialize_dotfiles() {
    function run_chezmoi() {
        sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "${DOTFILES_REPO_URL}"
    }
    function cleanup_chezmoi() {
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
        echo "Invalid system: ${system}; expected \`client\` or \`server\`"
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

    initialize_os_env
    initialize_dotfiles
    restart_shell
}

main "$@"
