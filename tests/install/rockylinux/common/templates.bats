#!/usr/bin/env bats

readonly SCRIPT_TEMPLATE_DIR="./home/.chezmoiscripts/ubuntu"
readonly EXTERNAL_TEMPLATE="./home/.chezmoiexternal.yaml.tmpl"
readonly TMUX_TEMPLATE="./home/dot_tmux.conf.tmpl"

@test "[rockylinux-common] required Linux templates route Rocky Linux to Rocky scripts" {
    local template

    for template in \
        run_once_00-setup-ssh.sh.tmpl \
        run_once_08-install-tmux.sh.tmpl \
        run_once_before_40-setup-timezone.sh.tmpl \
        run_once_before_50-common-dependencies.sh.tmpl; do
        run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
        run grep -F '../install/rockylinux/' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
    done
}

@test "[rockylinux-server] server templates route Rocky Linux to Rocky scripts" {
    local template

    for template in \
        run_once_50-server-install-mics.sh.tmpl \
        run_once_50-server-setup-locale.sh.tmpl; do
        run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
        run grep -F '../install/rockylinux/server/' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
    done
}

@test "[rockylinux-server] Starship installer uses the portable system shell" {
    run grep -F 'curl -sS "${url}" | POSIXLY_CORRECT=1 sh -s --' ./install/ubuntu/server/starship.sh
    [ "${status}" -eq 0 ]
}

@test "[rockylinux-common] external template accepts Rocky Linux" {
    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${EXTERNAL_TEMPLATE}"
    [ "${status}" -eq 0 ]
}

@test "[rockylinux-server] tmux template accepts Rocky Linux" {
    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${TMUX_TEMPLATE}"
    [ "${status}" -eq 0 ]
    run grep -F 'include "dot_tmux.conf.d/os/ubuntu_server.conf"' "${TMUX_TEMPLATE}"
    [ "${status}" -eq 0 ]
}

@test "[rockylinux-server] SSH environment template configures the Rocky server" {
    local template="./home/.chezmoiscripts/rockylinux/run_once_50-server-configure-ssh-env.sh.tmpl"

    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${template}"
    [ "${status}" -eq 0 ]
    run grep -F '../install/rockylinux/server/ssh_server.sh' "${template}"
    [ "${status}" -eq 0 ]
}

@test "[rockylinux-common] GPG agent template selects the Rocky terminal pinentry" {
    local template="./home/private_dot_gnupg/gpg-agent.conf.tmpl"

    run grep -F 'else if eq .chezmoi.osRelease.id "rocky"' "${template}"
    [ "${status}" -eq 0 ]
    run grep -F 'pinentry-program /usr/bin/pinentry-curses' "${template}"
    [ "${status}" -eq 0 ]
}
