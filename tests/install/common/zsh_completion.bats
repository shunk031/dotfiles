#!/usr/bin/env bats

# @file tests/install/common/zsh_completion.bats
# @brief Verify eager, cache-aware completion initialization in Sheldon output.
# @description
#   Renders both system variants, checks the queue order, and executes the
#   rendered compinit block with instrumentation for the exactly-once contract.

bats_require_minimum_version 1.5.0

readonly SHELDON_TEMPLATE_SOURCE="./home/dot_config/exact_sheldon/plugins.toml.tmpl"

render_sheldon_plugins() {
    local system="$1"
    local output_path="$2"

    chezmoi --source "${PWD}" execute-template \
        --override-data "{\"system\":\"${system}\"}" \
        --file "${SHELDON_TEMPLATE_SOURCE}" > "${output_path}"
}

@test "[common] compinit is eager and ordered after syntax highlighting for client and server" {
    local system rendered compinit_section syntax_section

    for system in client server; do
        rendered="${BATS_TEST_TMPDIR}/${system}-plugins.toml"
        render_sheldon_plugins "${system}" "${rendered}"

        run grep -F "zsh-defer compinit" "${rendered}"
        [ "${status}" -ne 0 ]

        run grep -Ec '^[[:space:]]*autoload -Uz compinit$' "${rendered}"
        [ "${status}" -eq 0 ]
        [ "${output}" -eq 1 ]

        run grep -F "zsh-defer -t 0.1 source" "${rendered}"
        [ "${status}" -eq 0 ]

        compinit_section="$(grep -n '^\[plugins\.compinit\]$' "${rendered}" | cut -d: -f1)"
        syntax_section="$(grep -n '^\[plugins\.zsh-syntax-highlighting\]$' "${rendered}" | cut -d: -f1)"
        [ "${compinit_section}" -lt "${syntax_section}" ]
    done
}

@test "[common] rendered compinit runs once and exposes completion functions" {
    local system rendered inline_script

    for system in client server; do
        rendered="${BATS_TEST_TMPDIR}/${system}-plugins.toml"
        inline_script="${BATS_TEST_TMPDIR}/${system}-compinit.zsh"
        render_sheldon_plugins "${system}" "${rendered}"
        {
            printf '%s\n' \
                'typeset -gi compinit_calls=0' \
                'autoload -Uz compinit' \
                'functions -c compinit __real_compinit' \
                'function compinit() { ((++compinit_calls)); __real_compinit "$@"; }'
            awk '
                /^\[plugins\.compinit\]$/ { in_compinit = 1; next }
                in_compinit && /^inline = / { in_inline = 1; next }
                in_inline && $0 == "\047\047\047" { exit }
                in_inline { print }
            ' "${rendered}" | sed '/^autoload -Uz compinit$/d'
            printf '%s\n' \
                '(( compinit_calls == 1 ))' \
                "(( \${+functions[compdef]} ))" \
                'autoload -Uz _files' \
                "(( \${+functions[_files]} ))" \
                '[[ ! -o extendedglob ]]'
        } > "${inline_script}"

        mkdir -p "${BATS_TEST_TMPDIR}/home" "${BATS_TEST_TMPDIR}/zdotdir"
        run env \
            HOME="${BATS_TEST_TMPDIR}/home" \
            ZDOTDIR="${BATS_TEST_TMPDIR}/zdotdir" \
            zsh -f "${inline_script}"
        [ "${status}" -eq 0 ]
    done
}
