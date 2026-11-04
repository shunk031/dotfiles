#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles own Herdr hooks and keep Claude settings in a regular file" {
    local settings legacy_source_settings original
    settings="${HOME}/.claude/settings.json"
    legacy_source_settings="${BATS_TEST_DIRNAME}/../../home/private_dot_config/claude/settings.json"
    original="$(< "${legacy_source_settings}")"

    [ -f "${settings}" ]
    [ ! -L "${settings}" ]
    run jq -e --arg command 'bash "$HOME/.claude/hooks/herdr-agent-state.sh" session' \
        '[.hooks.SessionStart[].hooks[] | select(.command == $command)] | length == 1' "${settings}"
    [ "${status}" -eq 0 ]

    [ ! -L "${HOME}/.claude/hooks" ]
    [ -f "${HOME}/.claude/hooks/enforce-uv.sh" ]
    [ ! -L "${HOME}/.claude/hooks/enforce-uv.sh" ]
    run grep -Fx '# HERDR_INTEGRATION_ID=claude' "${HOME}/.claude/hooks/herdr-agent-state.sh"
    [ "${status}" -eq 0 ]
    run grep -Fx '# HERDR_INTEGRATION_ID=codex' "${HOME}/.codex/herdr-agent-state.sh"
    [ "${status}" -eq 0 ]
    command -v herdr
    run python3 -m unittest discover -s "${BATS_TEST_DIRNAME}/../python" -p test_herdr_integration.py
    [ "${status}" -eq 0 ]
    [ "$(< "${legacy_source_settings}")" = "${original}" ]
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
