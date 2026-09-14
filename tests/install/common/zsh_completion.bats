#!/usr/bin/env bats

@test "[common] compinit is rendered before syntax highlighting" {
    for system in client server; do
        rendered="${BATS_TEST_TMPDIR}/${system}.toml"
        chezmoi --source "${PWD}" execute-template \
            --override-data "{\"system\":\"${system}\"}" \
            < home/dot_config/exact_sheldon/plugins.toml.tmpl > "${rendered}"
        compinit="$(grep -n '^\[plugins\.compinit\]$' "${rendered}" | cut -d: -f1)"
        syntax="$(grep -n '^\[plugins\.zsh-syntax-highlighting\]$' "${rendered}" | cut -d: -f1)"
        [ "${compinit}" -lt "${syntax}" ]
    done
}
