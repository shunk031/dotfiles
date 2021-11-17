#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

get_homebrew_git_config_file_path() {

    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if path="$(brew --repository 2> /dev/null)/.git/config"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get config file path)"
        return 1
    fi

}

install_homebrew() {

    if ! cmd_exists "brew"; then
        printf "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" &> /dev/null
        #  └─ simulate the ENTER keypress
    fi

    print_result $? "Homebrew"

}

opt_out_of_analytics() {

    brew analytics off
    print_result $? "Homebrew (opt-out of analytics)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n   Homebrew\n\n"

    install_homebrew
    opt_out_of_analytics

    brew_update
    brew_upgrade

}

main
