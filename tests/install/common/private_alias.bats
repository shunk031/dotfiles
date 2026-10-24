#!/usr/bin/env bats

readonly PUBLIC_DOTFILES_ROOT="."

@test "[common] Bash startup files load the optional private alias fragment" {
    local temp_home="${BATS_TEST_TMPDIR}/home"
    local startup_file

    mkdir -p "${temp_home}/.config/alias" "${temp_home}/.local/bin/server" "${temp_home}/.local/bin/common"
    cat > "${temp_home}/.config/alias/private.bash" << 'EOF'
PATH="${PATH:+${PATH}:}${HOME}/.flava/bin"
export PATH
EOF

    for startup_file in \
        .local/bin/server/prompt.sh \
        .local/bin/server/history.sh \
        .local/bin/server/aliases.sh \
        .local/bin/server/secrets.sh \
        .local/bin/server/cache.sh \
        .local/bin/common/dev \
        .local/bin/common/git-delete-merged-branches; do
        : > "${temp_home}/${startup_file}"
    done

    run env HOME="${temp_home}" PATH="/usr/bin:/bin" /bin/bash --noprofile --norc -c \
        'source "$1"; [[ ":${PATH}:" == *":${HOME}/.flava/bin:"* ]]' \
        bash "${PUBLIC_DOTFILES_ROOT}/home/dot_profile"
    [ "${status}" -eq 0 ]

    for startup_file in home/exact_dot_bash/client/bashrc home/exact_dot_bash/server/bashrc; do
        run env HOME="${temp_home}" PATH="/usr/bin:/bin" TERM=dumb \
            /bin/bash --noprofile --norc -c \
            'set -i; source "$1"; [[ ":${PATH}:" == *":${HOME}/.flava/bin:"* ]]' \
            bash "${PUBLIC_DOTFILES_ROOT}/${startup_file}"
        [ "${status}" -eq 0 ]
    done
}
