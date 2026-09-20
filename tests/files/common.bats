#!/usr/bin/env bats

# bats file_tags=common
@test "[common] Herdr owns one Claude hook without modifying the settings source" {
    local settings source_settings original
    settings="${HOME}/.claude/settings.json"
    source_settings="${BATS_TEST_DIRNAME}/../../home/dot_config/claude/settings.json"
    original="$(< "${source_settings}")"

    [ ! -L "${settings}" ]
    run jq -e '[.. | objects | .command? // empty | select(contains("herdr-agent-state.sh"))] | length == 0' "${source_settings}"
    [ "${status}" -eq 0 ]

    for attempt in 1 2; do
        run "${HOME}/.local/bin/mise" exec -- herdr integration install claude
        [ "${status}" -eq 0 ]
        run jq -e '[.. | objects | .command? // empty | select(contains("herdr-agent-state.sh"))] | length == 1' "${settings}"
        [ "${status}" -eq 0 ]
        [ "$(< "${source_settings}")" = "${original}" ]
    done
}

@test "[common] dotfiles" {
    files_exists=(
        "${HOME}/.config/git/ignore"
        "${HOME}/.config/git/config"
        "${HOME}/.config/jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings.json"
        "${HOME}/.config/tango.yml"
        "${HOME}/.local/bin/common/dev"
        "${HOME}/.local/bin/common/setup-gh"
        "${HOME}/.local/bin/common/setup-gh-cgd"
        "${HOME}/.gnupg/gpg-agent.conf"
        "${HOME}/.ssh/config"
        "${HOME}/.vimrc"
        "${HOME}/.tmux.conf"
        "${HOME}/.zshrc"
    )
    for file in "${files_exists[@]}"; do
        echo "Checking ${file}"
        [ -f "${file}" ]
    done

    directories_exists=(
        "${HOME}/.spacemacs.d"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
