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
    [ -L "${HOME}/.claude/hooks/enforce-uv.sh" ]
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

@test "[common] server bashrc leaves non-interactive commands in Bash" {
    local bashrc
    bashrc="${BATS_TEST_DIRNAME}/../../home/exact_dot_bash/server/bashrc"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    printf '#!/bin/sh\nprintf "zsh\\n"\n' > "${BATS_TEST_TMPDIR}/bin/zsh"
    chmod +x "${BATS_TEST_TMPDIR}/bin/zsh"

    run env \
        HOME="${BATS_TEST_TMPDIR}" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        TERM=xterm \
        BASH_ENV="${bashrc}" \
        bash -c 'echo ok'
    [ "${status}" -eq 0 ]
    [ "${output}" = "ok" ]
}

@test "[common] server bashrc switches interactive Bash to zsh" {
    local bashrc
    bashrc="${BATS_TEST_DIRNAME}/../../home/exact_dot_bash/server/bashrc"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    printf '#!/bin/sh\nprintf "zsh\\n"\n' > "${BATS_TEST_TMPDIR}/bin/zsh"
    chmod +x "${BATS_TEST_TMPDIR}/bin/zsh"

    run env \
        HOME="${BATS_TEST_TMPDIR}" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        TERM=xterm \
        bash --noprofile --rcfile "${bashrc}" -i -c 'echo after-bash'
    [ "${status}" -eq 0 ]
    [[ "${output}" == *zsh* ]]
    [[ "${output}" != *after-bash* ]]

    run env \
        HOME="${BATS_TEST_TMPDIR}" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        TERM=dumb \
        bash --noprofile --rcfile "${bashrc}" -i -c 'echo after-bash'
    [ "${status}" -eq 0 ]
    [[ "${output}" == *after-bash* ]]
    [[ "${output}" != *zsh* ]]
}
