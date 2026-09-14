#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/iterm2.sh"
readonly PREFERENCES_TEMPLATE_PATH="./home/.chezmoitemplates/chezmoiscripts.d/macos/iterm2.sh.tmpl"
readonly RECONCILE_TEMPLATE_PATH="./home/.chezmoiscripts/macos/run_after_04-reconcile-iterm2-preferences.sh.tmpl"
readonly DYNAMIC_PROFILE_TEMPLATE_PATH="./home/private_Library/private_Application Support/iTerm2/exact_DynamicProfiles/symlink_hotkey_window.json.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export ITERM2_DEFAULTS_CALLS_PATH="${BATS_TEST_TMPDIR}/defaults_calls.txt"

    mkdir -p "${HOME}/.local/share/chezmoi/home/dot_config/iterm2"
    : > "${HOME}/.local/share/chezmoi/home/dot_config/iterm2/com.googlecode.iterm2.plist"
    rm -f "${ITERM2_DEFAULTS_CALLS_PATH}"
}

@test "[common] iTerm2 preferences keep the canonical source path" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"

        function defaults() {
            if [ "$1" = "read" ] && [ "$3" = "PrefsCustomFolder" ]; then
                printf "%s\n" "~/.local/share/chezmoi/home/dot_config/iterm2/"
                return 0
            fi
            if [ "$1" = "read" ] && [ "$3" = "LoadPrefsFromCustomFolder" ]; then
                printf "%s\n" "1"
                return 0
            fi
            printf "%s\n" "$*" >> "${ITERM2_DEFAULTS_CALLS_PATH}"
        }
        function plutil() { return 0; }

        reconcile_iterm2_preferences_source
    '

    [ "${status}" -eq 0 ]
    [ ! -e "${ITERM2_DEFAULTS_CALLS_PATH}" ]
}

@test "[common] iTerm2 preferences replace a disposable worktree path" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"

        function defaults() {
            if [ "$1" = "read" ] && [ "$3" = "PrefsCustomFolder" ]; then
                printf "%s\n" "/tmp/dotfiles-worktree/home/dot_config/iterm2/"
                return 0
            fi
            if [ "$1" = "read" ] && [ "$3" = "LoadPrefsFromCustomFolder" ]; then
                printf "%s\n" "0"
                return 0
            fi
            printf "%s\n" "$*" >> "${ITERM2_DEFAULTS_CALLS_PATH}"
        }
        function plutil() { return 0; }

        reconcile_iterm2_preferences_source
    '

    [ "${status}" -eq 0 ]
    [ "$(< "${ITERM2_DEFAULTS_CALLS_PATH}")" = $'write com.googlecode.iterm2 PrefsCustomFolder ~/.local/share/chezmoi/home/dot_config/iterm2/\nwrite com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true' ]
}

@test "[common] iTerm2 preferences reject a malformed source plist" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"

        function defaults() {
            printf "%s\n" "$*" >> "${ITERM2_DEFAULTS_CALLS_PATH}"
        }
        function plutil() { return 1; }

        reconcile_iterm2_preferences_source
    '

    [ "${status}" -eq 1 ]
    [[ "${output}" == *"iTerm2 preferences plist is missing or malformed"* ]]
    [ ! -e "${ITERM2_DEFAULTS_CALLS_PATH}" ]
}

@test "[common] iTerm2 persistent references do not contain rendered absolute roots" {
    run grep -E '\.chezmoi\.(sourceDir|homeDir)' "${PREFERENCES_TEMPLATE_PATH}"
    [ "${status}" -eq 1 ]

    run grep -E '\.chezmoi\.(sourceDir|homeDir)' "${DYNAMIC_PROFILE_TEMPLATE_PATH}"
    [ "${status}" -eq 1 ]

    [ "$(< "${PREFERENCES_TEMPLATE_PATH}")" = "reconcile_iterm2_preferences_source" ]
    [ "$(< "${DYNAMIC_PROFILE_TEMPLATE_PATH}")" = '../../../../.local/share/chezmoi/home/dot_config/iterm2/hotkey_window.json' ]
}

@test "[common] iTerm2 preferences are reconciled after every apply" {
    [ -f "${RECONCILE_TEMPLATE_PATH}" ]

    run grep -F 'reconcile_iterm2_preferences_source' "${RECONCILE_TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
}
