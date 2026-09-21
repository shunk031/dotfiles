#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles own Herdr hooks and preserve the Claude settings symlink" {
    local settings source_settings original agent
    settings="${HOME}/.claude/settings.json"
    source_settings="${BATS_TEST_DIRNAME}/../../home/dot_config/claude/settings.json"
    original="$(< "${source_settings}")"

    [ -L "${settings}" ]
    [ "${settings}" -ef "${source_settings}" ]
    run jq -e --arg command 'bash "$HOME/.local/share/herdr/hooks/claude-agent-state.sh" session' \
        '[.hooks.SessionStart[].hooks[] | select(.command == $command)] | length == 1' "${settings}"
    [ "${status}" -eq 0 ]

    for agent in claude codex; do
        run grep -Fx "# HERDR_INTEGRATION_ID=${agent}" "${HOME}/.local/share/herdr/hooks/${agent}-agent-state.sh"
        [ "${status}" -eq 0 ]
        run env HERDR_ENV=0 bash "${HOME}/.local/share/herdr/hooks/${agent}-agent-state.sh" session <<< '{}'
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
