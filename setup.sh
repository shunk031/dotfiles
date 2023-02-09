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

function initialize_macos() {
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

    install_xcode
    echo "Finish to pre-initialize MacOS"
}

function initialize_linux() {
    echo "Finish to pre-initialize Linux OS"
}

function initialize_os_env() {
    local ostype
    ostype="$(get_os_type)"

    if [ "${ostype}" == "Darwin" ]; then
        initialize_macos
    elif [ "${ostype}" == "Linux" ]; then
        initialize_linux
    else
        echo "Invalid OS type: ${ostype}" >&2
        exit 1
    fi
}

function initialize_dotfiles() {
    function keepalive_sudo() {
        function keepalive_sudo_linux() {
            # Might as well ask for password up-front, right?
            echo "Checking for \`sudo\` access which may request your password."
            sudo -v

            # Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
            while true; do
                sudo -n true
                sleep 60
                kill -0 "$$" || exit
            done 2>/dev/null &
        }
        function keepalive_sudo_macos() {
            # ref. https://github.com/reitermarkus/dotfiles/blob/master/.sh#L85-L116
            (
                builtin read -r -s -p "Password: " </dev/tty
                builtin echo "add-generic-password -U -s 'dotfiles' -a '${USER}' -w '${REPLY}'"
            ) | /usr/bin/security -i
            printf "\n"
            at_exit "
                echo -e '\033[0;31mRemoving password from Keychain …\033[0m'
                /usr/bin/security delete-generic-password -s 'dotfiles' -a '${USER}'
            "
            SUDO_ASKPASS="$(/usr/bin/mktemp)"
            at_exit "
                echo -e '\033[0;31mDeleting SUDO_ASKPASS script …\033[0m'
                /bin/rm -f '${SUDO_ASKPASS}'
            "
            {
                echo "#!/bin/sh"
                echo "/usr/bin/security find-generic-password -s 'dotfiles' -a '${USER}' -w"
            } >"${SUDO_ASKPASS}"

            /bin/chmod +x "${SUDO_ASKPASS}"
            export SUDO_ASKPASS

            if ! /usr/bin/sudo -A -kv 2>/dev/null; then
                echo -e '\033[0;31mIncorrect password.\033[0m' 1>&2
                exit 1
            fi
        }

        local ostype
        ostype="$(get_os_type)"

        if [ "${ostype}" == "Darwin" ]; then
            keepalive_sudo_macos
        elif [ "${ostype}" == "Linux" ]; then
            keepalive_sudo_linux
        else
            echo "Invalid OS type: ${ostype}" >&2
            exit 1
        fi
    }
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
        sh -c "$(curl -fsLS get.chezmoi.io)" -- init "${DOTFILES_REPO_URL}" --apply "${no_tty_option}"
    }
    function cleanup_chezmoi() {
        # remove the chezmoi binary without prompt as described above.
        rm -f "${HOME}/bin/chezmoi"
    }

    if ! "${CI:-false}"; then
        # - /dev/tty of the github workflow is not available.
        # - We can use password-less sudo in the github workflow.
        # Therefore, skip the sudo keep alive function.
        keepalive_sudo
    fi

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

    initialize_os_env
    initialize_dotfiles

    # restart_shell # Disabled because the at_exit function does not work properly.
}

main "$@"
