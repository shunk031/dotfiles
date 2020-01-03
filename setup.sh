#!/bin/bash

set -Ce

# shellcheck disable=SC1078,SC1079,SC2016
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

                     *** This is dotfiles setup script ***
                1. Download https://github.com/shunk031/dotfiles
                2. Symlink dotfiles to your home directory

'

declare -r GITHUB_REPOSITORY="shunk031/dotfiles"

declare -r DOTFILES_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r DOTFILES_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/master"
declare -r DOTFILES_UTIL_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/master/install/util.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare dotfiles_directory="$HOME/.dotfiles"
declare is_skip_questions=false

download() {
    local url="$1"
    local output="$2"

    if command -v "curl" &> /dev/null; then

        curl -LsSo "${output}" "${url}" &> /dev/null
        #     │││└─ write output to file
        #     ││└─ show error messages
        #     │└─ don't show the progress meter
        #     └─ follow redirects

        return $?

    elif command -v "wget" &> /dev/null; then

        wget -qO "$output" "$url" &> /dev/null
        #     │└─ write output to file
        #     └─ don't show output

        return $?
    fi

    return 1
}

download_dotfiles() {
    local tmp_file=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_purple "\n • Download and extract archive\n\n"

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "$DOTFILES_TARBALL_URL" "$tmp_file"
    print_result $? "Download archive" "true"
    printf "\n"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! $is_skip_questions; then
        ask_for_confirmation "Do you want to store the dotfiles in '$dotfiles_directory'?"

        if ! answer_is_yes; then
            dotfiles_directory=""
            while [ -z "$dotfiles_directory" ]; do
                ask "Please specify another location for the dotfiles (path): "
                dotfiles_directory="$(get_answer)"
            done
        fi

        # Ensure the `dotfiles` directory is available

        while [ -e "$dotfiles_directory" ]; do
            ask_for_confirmation "'$dotfiles_directory' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$dotfiles_directory"
                break
            else
                dotfiles_directory=""
                while [ -z "$dotfiles_directory" ]; do
                    ask "Please specify another location for the dotfiles (path): "
                    dotfiles_directory="$(get_answer)"
                done
            fi
        done

        printf "\n"

    else
        rm -rf "$dotfiles_directory" &> /dev/null
    fi

    mkdir -p "$dotfiles_directory"
    print_result $? "Create '$dotfiles_directory'" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Extract archive in the `dotfiles` directory.

    extract "$tmp_file" "$dotfiles_directory"
    print_result $? "Extract archive" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    rm -rf "$tmp_file"
    print_result $? "Remove archive\n"
}

download_util() {
    local tmp_file=""

    tmp_file="$(mktemp /tmp/XXXXX)"

    download "${DOTFILES_UTIL_URL}" "${tmp_file}" \
        && . "$tmp_file" \
        && rm -rf "$tmp_file" \
        && return 0

    return 1
}

extract() {
    local archive="$1"
    local output_dir="$2"

    if command -v "tar" &> /dev/null; then
        tar -zxf "$archive" --strip-components 1 -C "$output_dir"
        return $?
    fi

    return 1
}

verify_os() {

    declare -r MINIMUM_MACOS_VERSION="10.10"
    declare -r MINIMUM_UBUNTU_VERSION="18.04"

    local os_name="$(get_os)"
    local os_version="$(get_os_version)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `macOS` and
    # it's above the required version.

    if [ "$os_name" == "macos" ]; then

        if is_supported_version "$os_version" "$MINIMUM_MACOS_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for macOS %s+" "$MINIMUM_MACOS_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `Ubuntu` and
    # it's above the required version.

    elif [ "$os_name" == "ubuntu" ]; then

        if is_supported_version "$os_version" "$MINIMUM_UBUNTU_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for Ubuntu %s+" "$MINIMUM_UBUNTU_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    else
        printf "Sorry, this script is intended only for macOS and Ubuntu!"
    fi

    return 1
}

# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

    echo "$DOTFILES_LOGO"

    # Ensure that the following actions
    # are made relative to this file's path.

    cd "$(dirname "${BASH_SOURCE[0]}")" \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Load utils
    if [ -x "install/util.sh" ]; then
        . "install/util.sh" || exit 1
    else
        download_util || exit 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Ensure the OS is supported and
    # it's above the required version.

    verify_os \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && is_skip_questions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Check if this script was run directly (./<path>/setup.sh),
    # and if not, it most likely means that the dotfiles were not
    # yet set up, and they will need to be downloaded.
    printf "%s" "${BASH_SOURCE[0]}" | grep "setup.sh" &> /dev/null \
        || download_dotfiles

    make deploy
    make local
    make init

    # Restart shell if specified "bash -c $(curl -L {URL})"
    # not restart:
    #   curl -L {URL} | bash
    if [ -p /dev/stdin ]; then
        print_in_yellow "Now continue with Rebooting your shell"
    else
        print_success "Restarting your shell..."
        exec "${SHELL:-$(which zsh)}"
    fi
}

main "$@"
