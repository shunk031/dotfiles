#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"
readonly TMPL_SCRIPT_GLOB="./home/.chezmoiscripts/common/run_once_after_*-install-mise.sh.tmpl"
readonly RUN_AFTER_TEMPLATE="./home/.chezmoiscripts/common/run_after_20-install-mise-tools.sh.tmpl"
readonly MISE_CONFIG_SOURCE="./home/dot_mise/config.toml"
readonly MISE_BASH_SOURCE="./home/dot_config/exact_shell/mise.bash"
readonly MISE_ZSH_SOURCE="./home/dot_config/exact_shell/mise.zsh"
readonly ZSHENV_SOURCE="./home/dot_zshenv"
readonly ZPROFILE_SOURCE="./home/dot_zprofile.tmpl"
readonly SHELDON_COMMON_SOURCE="./home/dot_config/exact_sheldon/plugin_sources/common.toml"
readonly SHELDON_CLIENT_SOURCE="./home/dot_config/exact_sheldon/plugin_sources/client/common.toml"
readonly SHELDON_SERVER_SOURCE="./home/dot_config/exact_sheldon/plugin_sources/server.toml"
readonly SHELDON_TEMPLATE_SOURCE="./home/dot_config/exact_sheldon/plugins.toml.tmpl"
readonly MISE_SETUP_WORKFLOWS=(
    "./.github/workflows/e2e-ubuntu.yaml"
    "./.github/workflows/e2e-rockylinux.yaml"
    "./.github/workflows/e2e-macos.yaml"
)

function write_mise_config() {
    local version="$1"

    cat > "${MISE_CONFIG_PATH}" << EOF
min_version = "${version}"

[tools]
EOF
}

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_calls.txt"
    export MISE_ZSH_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_zsh_calls.txt"
    export GH_CALLS_PATH="${BATS_TEST_TMPDIR}/gh_calls.txt"
    export MISE_CONFIG_PATH="${BATS_TEST_TMPDIR}/mise_config.toml"
    export RUN_AFTER_SCRIPT="${BATS_TEST_TMPDIR}/run_after_20-install-mise-tools.sh"
    export BATS_TEST_TMPDIR
    PATH="${TEST_BIN_DIR}:${HOME}/.local/bin:$(getconf PATH)"
    export PATH

    mkdir -p "${HOME}/.local/bin" "${TEST_BIN_DIR}"
    rm -f \
        "${MISE_CALLS_PATH}" \
        "${MISE_ZSH_CALLS_PATH}" \
        "${GH_CALLS_PATH}" \
        "${BATS_TEST_TMPDIR}/curl_args.txt" \
        "${BATS_TEST_TMPDIR}/installer_env.txt"
    unset GITHUB_TOKEN

    write_mise_config "2026.6.13"
    render_run_after_template
    source "${SCRIPT_PATH}"
}

function teardown() {
    if [ -e "${MISE_INSTALL_PATH}" ]; then
        uninstall_mise
    fi
}

function render_run_after_template() {
    local content source_dir

    source_dir="./home"
    content="$(< "${RUN_AFTER_TEMPLATE}")"
    content="${content//'{{ .chezmoi.sourceDir }}'/${source_dir}}"
    printf '%s\n' "${content}" > "${RUN_AFTER_SCRIPT}"
    chmod +x "${RUN_AFTER_SCRIPT}"
}

function write_herdr_stub() {
    local herdr_path="${TEST_BIN_DIR}/herdr"

    cat > "${herdr_path}" << 'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "${HERDR_CALLS_PATH}"
case "$*" in
    --version)
        printf '%s\n' 'herdr 0.8.0'
        ;;
    --skill)
        printf '%s\n' 'generated Herdr skill'
        ;;
esac
EOF

    chmod +x "${herdr_path}"
}

function write_mise_stub() {
    local version="${1:-2026.6.13}"

    cat > "${MISE_INSTALL_PATH}" << EOF
#!/usr/bin/env bash

case "\$1" in
    --version)
        printf 'mise ${version}\\n'
        ;;
    activate)
        if [ "\${2:-}" = "zsh" ]; then
            printf '%s\\n' "\$*" >> "\${MISE_ZSH_CALLS_PATH}"
            if [ "\${3:-}" = "--shims" ]; then
                printf 'export MISE_ACTIVATION_MODE=shims\\n'
                printf 'export PATH="%s:\$PATH"\\n' "\${HOME}/.local/share/mise/shims"
            else
                printf 'function _mise_hook { :; }\\n'
                printf 'typeset -ag precmd_functions\\n'
                printf 'precmd_functions+=( _mise_hook )\\n'
                printf 'export MISE_ACTIVATION_MODE=full\\n'
                printf 'export PATH="%s:\$PATH"\\n' "\$(dirname "\${MISE_INSTALL_PATH}")"
            fi
        elif [ "\${2:-}" = "bash" ] && [ "\${3:-}" = "--shims" ]; then
            printf 'export PATH="%s:\$PATH"\\n' "\${HOME}/.local/share/mise/shims"
        else
            printf 'export PATH="%s:\$PATH"\\n' "\$(dirname "\${MISE_INSTALL_PATH}")"
        fi
        ;;
    install)
        printf 'install\\n' >> "\${MISE_CALLS_PATH}"
        printf 'MISE_CURRENT_VERSION=%s\\n' "\${MISE_CURRENT_VERSION:-}" >> "\${MISE_CALLS_PATH}"
        printf 'MISE_VERSION=%s\\n' "\${MISE_VERSION:-}" >> "\${MISE_CALLS_PATH}"
        printf 'GITHUB_TOKEN=%s\\n' "\${GITHUB_TOKEN:-}" >> "\${MISE_CALLS_PATH}"
        ;;
    exec)
        printf 'exec %s\\n' "\${*:2}" >> "\${MISE_CALLS_PATH}"
        if [ "\${2:-}" = "--" ]; then
            shift 2
            "\$@"
        fi
        ;;
esac
EOF

    chmod +x "${MISE_INSTALL_PATH}"
}

function write_curl_installer_stub() {
    cat > "${TEST_BIN_DIR}/curl" << 'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" > "${BATS_TEST_TMPDIR}/curl_args.txt"

output_path=""
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ]; then
        output_path="$2"
        shift 2
    else
        shift
    fi
done

cat > "${output_path}" << 'INSTALLER'
#!/usr/bin/env bash

printf 'MISE_VERSION=%s\n' "${MISE_VERSION:-}" > "${BATS_TEST_TMPDIR}/installer_env.txt"
cat > "${MISE_INSTALL_PATH}" << 'MISE'
#!/usr/bin/env bash

case "$1" in
    --version)
        printf 'mise 2026.6.13\n'
        ;;
    activate)
        if [ "${2:-}" = "bash" ] && [ "${3:-}" = "--shims" ]; then
            printf 'export PATH="%s:$PATH"\n' "${HOME}/.local/share/mise/shims"
        else
            printf 'export PATH="%s:$PATH"\n' "$(dirname "${MISE_INSTALL_PATH}")"
        fi
        ;;
    install)
        printf 'install\n' >> "${MISE_CALLS_PATH}"
        printf 'MISE_CURRENT_VERSION=%s\n' "${MISE_CURRENT_VERSION:-}" >> "${MISE_CALLS_PATH}"
        printf 'MISE_VERSION=%s\n' "${MISE_VERSION:-}" >> "${MISE_CALLS_PATH}"
        printf 'GITHUB_TOKEN=%s\n' "${GITHUB_TOKEN:-}" >> "${MISE_CALLS_PATH}"
        ;;
    exec)
        printf 'exec %s\n' "${*:2}" >> "${MISE_CALLS_PATH}"
        if [ "${2:-}" = "--" ]; then
            shift 2
            "$@"
        fi
        ;;
esac
MISE
chmod +x "${MISE_INSTALL_PATH}"
INSTALLER
EOF

    chmod +x "${TEST_BIN_DIR}/curl"
}

function write_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${GH_CALLS_PATH}"
printf "stub-token\n"
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

function write_failing_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${GH_CALLS_PATH}"
exit 1
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

function write_chezmoi_shim() {
    local shims_dir="${HOME}/.local/share/mise/shims"

    mkdir -p "${shims_dir}"
    cat > "${shims_dir}/chezmoi" << 'EOF'
#!/usr/bin/env bash

printf 'chezmoi shim\n'
EOF
    chmod +x "${shims_dir}/chezmoi"
}

function run_mise_bash_startup() {
    run env -u BASH_ENV -u BASH_XTRACEFD -u SHELLOPTS -u PS4 bash -c "$1"
}

function install_zshenv_sources() {
    mkdir -p "${HOME}/.config/shell"
    cp "${ZSHENV_SOURCE}" "${HOME}/.zshenv"
    cp "${MISE_ZSH_SOURCE}" "${HOME}/.config/shell/mise.zsh"
}

function run_mise_zsh_startup() {
    command -v zsh > /dev/null 2>&1 || skip "zsh is not installed"
    run env -u ZDOTDIR -u BASH_ENV -u BASH_XTRACEFD -u SHELLOPTS -u PS4 zsh -f -c "$1"
}

function run_mise_zshenv_startup() {
    command -v zsh > /dev/null 2>&1 || skip "zsh is not installed"
    run env -u BASH_ENV -u BASH_XTRACEFD -u SHELLOPTS -u PS4 ZDOTDIR="${HOME}" zsh -c "$1"
}

function render_sheldon_plugins() {
    local system="$1"
    local output_path="$2"

    chezmoi --source "${PWD}" execute-template \
        --override-data "{\"system\":\"${system}\"}" \
        --file "${SHELDON_TEMPLATE_SOURCE}" > "${output_path}"
}

function render_zprofile() {
    local system="$1"
    local output_path="$2"

    chezmoi --source "${PWD}" execute-template \
        --override-data "{\"system\":\"${system}\"}" \
        --file "${ZPROFILE_SOURCE}" > "${output_path}"
}

@test "[common] mise config declares a parseable top-level min_version" {
    run get_mise_min_version_from_config "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
    [[ "${output}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]
}

@test "[common] mise version supports declarative system bootstrap and dangling npm install repair" {
    local min_version

    min_version="$(get_mise_min_version_from_config "${MISE_CONFIG_SOURCE}")"
    run is_mise_version_at_least "${min_version}" "2026.8.15"
    [ "${status}" -eq 0 ]
}

@test "[common] mise config pins fnox for command-backed authentication" {
    run get_mise_min_version_from_config "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2026.8.15" ]

    run awk '
        /^\[tools\]$/ { in_tools = 1; next }
        /^\[/ { in_tools = 0 }
        in_tools && $0 ~ /^fnox = "[0-9]+[.][0-9]+[.][0-9]+"$/ { found = 1 }
        END { exit !found }
    ' "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
}

@test "[common] setup workflows reuse the chezmoi-bootstrapped mise" {
    local workflow

    for workflow in "${MISE_SETUP_WORKFLOWS[@]}"; do
        run grep -F 'source "${HOME}/.config/shell/mise.bash"' "${workflow}"
        [ "${status}" -eq 0 ]

        run grep -F 'jdx/mise-action' "${workflow}"
        [ "${status}" -ne 0 ]
    done
}

@test "[common] mise bash startup exits cleanly when mise is absent" {
    local expected_path="${PATH}"

    run_mise_bash_startup 'source "'"${MISE_BASH_SOURCE}"'"; printf "%s\n" "${PATH}"'
    [ "${status}" -eq 0 ]
    [ "${output}" = "${expected_path}" ]
}

@test "[common] mise bash startup exposes mise and mise shims" {
    write_mise_stub
    write_chezmoi_shim

    run_mise_bash_startup 'source "'"${MISE_BASH_SOURCE}"'"; command -v mise; command -v chezmoi'
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${MISE_INSTALL_PATH}" ]
    [ "${lines[1]}" = "${HOME}/.local/share/mise/shims/chezmoi" ]
}

@test "[common] mise bash startup avoids duplicate PATH entries" {
    write_mise_stub
    write_chezmoi_shim

    run_mise_bash_startup '
        count_path_entry() {
            local entry="$1"

            printf "%s" "${PATH}" | tr : "\n" | awk -v entry="${entry}" "\$0 == entry { count++ } END { print count + 0 }"
        }

        source "'"${MISE_BASH_SOURCE}"'"
        source "'"${MISE_BASH_SOURCE}"'"
        count_path_entry "${HOME}/.local/bin"
        count_path_entry "${HOME}/.local/share/mise/shims"
    '
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "1" ]
    [ "${lines[1]}" = "1" ]
}

@test "[common] mise zsh startup leaves PATH unchanged when mise is absent" {
    local expected_path="${PATH}"

    run_mise_zsh_startup 'source "'"${MISE_ZSH_SOURCE}"'"; printf "%s\n" "${PATH}"'
    [ "${status}" -eq 0 ]
    [ "${output}" = "${expected_path}" ]
}

@test "[common] mise zsh startup exposes mise and mise shims" {
    write_mise_stub
    write_chezmoi_shim

    run_mise_zsh_startup 'source "'"${MISE_ZSH_SOURCE}"'"; command -v mise; command -v chezmoi'
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${MISE_INSTALL_PATH}" ]
    [ "${lines[1]}" = "${HOME}/.local/share/mise/shims/chezmoi" ]
}

@test "[common] mise zsh startup avoids duplicate PATH entries" {
    write_mise_stub
    write_chezmoi_shim

    run_mise_zsh_startup '
        count_path_entry() {
            local entry="$1"

            printf "%s" "${PATH}" | tr : "\n" | awk -v entry="${entry}" "\$0 == entry { count++ } END { print count + 0 }"
        }

        source "'"${MISE_ZSH_SOURCE}"'"
        source "'"${MISE_ZSH_SOURCE}"'"
        count_path_entry "${HOME}/.local/bin"
        count_path_entry "${HOME}/.local/share/mise/shims"
    '
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "1" ]
    [ "${lines[1]}" = "1" ]
}

@test "[common] zshenv sources only the minimal mise startup" {
    write_mise_stub
    write_chezmoi_shim
    install_zshenv_sources
    mkdir -p "${HOME}/private-bin"
    cat > "${HOME}/.zshenv_private" << EOF
export ZSHENV_PRIVATE_LOADED=1
export PATH="${HOME}/private-bin:\${PATH}"
EOF

    run_mise_zshenv_startup '
        printf "%s\n" "${PATH}" | tr : "\n" | awk "NR <= 2"
        command -v mise
        command -v chezmoi
        printf "private=%s\n" "${ZSHENV_PRIVATE_LOADED:-unset}"
        printf "%s %s %s\n" "${+_zshenv_mise}" "${+_mise_bin}" "${+_mise_shims}"
    '
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "${HOME}/.local/share/mise/shims" ]
    [ "${lines[1]}" = "${HOME}/.local/bin" ]
    [ "${lines[2]}" = "${MISE_INSTALL_PATH}" ]
    [ "${lines[3]}" = "${HOME}/.local/share/mise/shims/chezmoi" ]
    [ "${lines[4]}" = "private=unset" ]
    [ "${lines[5]}" = "0 0 0" ]
}

@test "[common] invalid zsh activation mode fails before mise lookup" {
    run_mise_zsh_startup '
        source "'"${MISE_ZSH_SOURCE}"'"
        mise_zsh_activate invalid
    '
    [ "${status}" -eq 2 ]

    write_mise_stub
    run_mise_zsh_startup '
        source "'"${MISE_ZSH_SOURCE}"'"
        mise_zsh_activate invalid
    '
    [ "${status}" -eq 2 ]
    [ ! -s "${MISE_ZSH_CALLS_PATH}" ]
}

@test "[common] client mise activation is full, synchronous, and runs once" {
    write_mise_stub

    run_mise_zsh_startup '
        source "'"${MISE_ZSH_SOURCE}"'"
        mise_zsh_activate client
        mise_zsh_activate client
        if (( ${+functions[_mise_hook]} )); then
            print hooks
        fi
        print "${MISE_ACTIVATION_MODE}"
    '
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "hooks" ]
    [ "${lines[1]}" = "full" ]
    [ "$(< "${MISE_ZSH_CALLS_PATH}")" = "activate zsh" ]
}

@test "[common] server mise activation uses shims and does not install hooks" {
    write_mise_stub

    run_mise_zsh_startup '
        source "'"${MISE_ZSH_SOURCE}"'"
        path=(${path:#${HOME}/.local/share/mise/shims})
        mise_zsh_activate server
        mise_zsh_activate server
        print "${MISE_ACTIVATION_MODE}"
        print -r -- "${path[(Ie)${HOME}/.local/share/mise/shims]}"
        if (( ${+functions[_mise_hook]} )); then
            print hooks
        fi
    '
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "shims" ]
    [ "${lines[1]}" = "1" ]
    [ "${#lines[@]}" -eq 2 ]
    [ "$(< "${MISE_ZSH_CALLS_PATH}")" = "activate zsh --shims" ]
}

@test "[common] child zsh reactivates client hooks without an exported marker" {
    write_mise_stub
    local child_script="source \"${MISE_ZSH_SOURCE}\"; mise_zsh_activate client; (( \${+functions[_mise_hook]} )) && print hooks"

    run_mise_zsh_startup "
        source \"${MISE_ZSH_SOURCE}\"
        mise_zsh_activate client
        zsh -f -c '${child_script}'
    "
    [ "${status}" -eq 0 ]
    [ "${output}" = "hooks" ]
    [ "$(< "${MISE_ZSH_CALLS_PATH}")" = $'activate zsh\nactivate zsh' ]
}

@test "[common] child zsh keeps one server shim PATH entry" {
    write_mise_stub
    local child_script="source \"${MISE_ZSH_SOURCE}\"; mise_zsh_activate server; print -r -- \"\${path[(Ie)\${HOME}/.local/share/mise/shims]}\""

    run_mise_zsh_startup "
        source \"${MISE_ZSH_SOURCE}\"
        path=(\${path:#\${HOME}/.local/share/mise/shims})
        mise_zsh_activate server
        zsh -f -c '${child_script}'
    "
    [ "${status}" -eq 0 ]
    [ "${output}" = "1" ]
    [ "$(< "${MISE_ZSH_CALLS_PATH}")" = "activate zsh --shims" ]
}

@test "[common] zsh startup keeps prompt-critical plugins eager" {
    local content template

    content="$(< "${SHELDON_COMMON_SOURCE}")"
    template="$(< "${SHELDON_TEMPLATE_SOURCE}")"

    [[ "${content}" == *"Keep zle-critical plugins eager"* ]]
    [[ "${template}" == *"zsh-syntax-highlighting"*"apply = ['source']"* ]]
    [[ "${content}" == *"zsh-autopair"*"apply = ['source']"* ]]
    [[ "${content}" == *"zsh-autosuggestions"*"apply = ['defer']"* ]]
    [[ "${content}" == *"zsh-completions"*"apply = ['defer']"* ]]
}

@test "[common] syntax highlighting is the last eager plugin for client and server" {
    local system rendered source_plugins last_index

    for system in client server; do
        rendered="${BATS_TEST_TMPDIR}/${system}-plugins.toml"
        render_sheldon_plugins "${system}" "${rendered}"
        mapfile -t source_plugins < <(
            awk '
                function emit() {
                    if (plugin != "" && (apply == "" || apply ~ /source/)) {
                        print plugin
                    }
                }
                /^\[plugins\./ {
                    emit()
                    plugin = $0
                    sub(/^\[plugins\./, "", plugin)
                    sub(/\]$/, "", plugin)
                    apply = ""
                    next
                }
                /^apply[[:space:]]*=/ { apply = $0; next }
                END { emit() }
            ' "${rendered}"
        )
        last_index=$((${#source_plugins[@]} - 1))
        [ "${source_plugins[$last_index]}" = "zsh-syntax-highlighting" ]
    done
}

@test "[common] mise activation is split between client and server Sheldon sources" {
    run grep -F 'mise_zsh_activate client' "${SHELDON_CLIENT_SOURCE}"
    [ "${status}" -eq 0 ]

    run grep -F 'mise_zsh_activate server' "${SHELDON_SERVER_SOURCE}"
    [ "${status}" -eq 0 ]

    run grep -F 'mise activate zsh' "${SHELDON_COMMON_SOURCE}"
    [ "${status}" -ne 0 ]
}

@test "[common] zprofile template selects the system activation mode" {
    run grep -F '{{- if eq .system "server" }}' "${ZPROFILE_SOURCE}"
    [ "${status}" -eq 0 ]

    run grep -F 'mise_zsh_activate server' "${ZPROFILE_SOURCE}"
    [ "${status}" -eq 0 ]

    run grep -F 'mise_zsh_activate client' "${ZPROFILE_SOURCE}"
    [ "${status}" -eq 0 ]
}

@test "[common] rendered zprofile and Sheldon inline activation run mise once" {
    local system rendered mode expected expected_call

    for system in client server; do
        rendered="${HOME}/.zprofile"
        render_zprofile "${system}" "${rendered}"
        mkdir -p "${HOME}/.config/shell"
        cp "${MISE_ZSH_SOURCE}" "${HOME}/.config/shell/mise.zsh"
        rm -f "${MISE_ZSH_CALLS_PATH}"
        write_mise_stub

        if [ "${system}" = client ]; then
            mode="client"
            expected="full"
            expected_call="activate zsh"
        else
            mode="server"
            expected="shims"
            expected_call="activate zsh --shims"
        fi

        run env -u ZDOTDIR -u BASH_ENV -u BASH_XTRACEFD -u SHELLOPTS -u PS4 \
            HOME="${HOME}" MISE_ZSH_CALLS_PATH="${MISE_ZSH_CALLS_PATH}" \
            zsh -d -l -i -c "mise_zsh_activate ${mode}; print \"\${MISE_ACTIVATION_MODE}\""
        [ "${status}" -eq 0 ]
        [ "${output}" = "${expected}" ]
        [ "$(wc -l < "${MISE_ZSH_CALLS_PATH}")" -eq 1 ]
        [ "$(< "${MISE_ZSH_CALLS_PATH}")" = "${expected_call}" ]
    done
}

@test "[common] get_mise_min_version_from_config reads top-level min_version" {
    write_mise_config "2026.6.13"

    run get_mise_min_version_from_config "${MISE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2026.6.13" ]
}

@test "[common] get_mise_release_tag_from_config normalizes the configured version" {
    write_mise_config "2026.6.13"

    run get_mise_release_tag_from_config "${MISE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "v2026.6.13" ]
}

@test "[common] get_mise_min_version_from_config rejects table-scoped min_version" {
    cat > "${MISE_CONFIG_PATH}" << 'EOF'
[tools]
min_version = "2026.6.13"
EOF

    run get_mise_min_version_from_config "${MISE_CONFIG_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] get_mise_min_version_from_config rejects malformed top-level min_version" {
    cat > "${MISE_CONFIG_PATH}" << 'EOF'
min_version = "v2026.6.13"

[tools]
EOF

    run get_mise_min_version_from_config "${MISE_CONFIG_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] install_mise does not invoke curl when min_version is invalid" {
    cat > "${MISE_CONFIG_PATH}" << 'EOF'
min_version = "v2026.6.13"

[tools]
EOF
    write_curl_installer_stub

    run install_mise
    [ "${status}" -ne 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
}

@test "[common] install_mise downloads and installs the configured mise release" {
    write_mise_config "2026.6.13"
    write_curl_installer_stub

    run install_mise
    [ "${status}" -eq 0 ]
    [ -x "${MISE_INSTALL_PATH}" ]
    [[ "$(< "${BATS_TEST_TMPDIR}/curl_args.txt")" == "-fsSL https://github.com/jdx/mise/releases/download/v2026.6.13/install.sh -o "* ]]
    [ "$(< "${BATS_TEST_TMPDIR}/installer_env.txt")" = "MISE_VERSION=v2026.6.13" ]
}

@test "[common] ensure_mise_min_version skips current mise" {
    write_mise_config "2026.6.13"
    write_mise_stub "2026.6.13"
    write_curl_installer_stub

    run ensure_mise_min_version
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
}

@test "[common] ensure_mise_min_version installs stale mise" {
    write_mise_config "2026.6.13"
    write_mise_stub "2026.6.12"
    write_curl_installer_stub

    run ensure_mise_min_version
    [ "${status}" -eq 0 ]
    [ -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
    [ "$(< "${BATS_TEST_TMPDIR}/installer_env.txt")" = "MISE_VERSION=v2026.6.13" ]
}

@test "[common] mise" {
    compgen -G "${TMPL_SCRIPT_GLOB}" > /dev/null
    write_curl_installer_stub

    DOTFILES_DEBUG=1 MISE_CONFIG_PATH="${MISE_CONFIG_PATH}" bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.local/bin"
    [ -x "$(command -v mise)" ]
    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
}

@test "[common] run_mise_install uses mise config release-age policy" {
    printf "min-release-age=99\n" > "${HOME}/.npmrc"
    write_mise_stub
    export MISE_CURRENT_VERSION="should-not-leak"
    export MISE_VERSION="should-not-leak"

    run run_mise_install
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
}

@test "[common] Codex CLI has a stable semver pin and is exempt from mise release age" {
    local codex_version

    codex_version="$(sed -nE 's/^[[:space:]]*"aqua:openai\/codex"[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' "${MISE_CONFIG_SOURCE}")"
    [[ "${codex_version}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]

    run grep -F '"aqua:openai/codex",' "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
}

@test "[common] run_after template installs pinned mise tools and syncs Herdr skill after apply" {
    write_mise_stub
    write_herdr_stub
    export HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_calls.txt"

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=\nexec -- herdr --version\nexec -- herdr --skill' ]

    run cat "${HERDR_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'--version\n--skill' ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "generated Herdr skill" ]
}

@test "[common] run_after template skips Herdr skill sync when Herdr is unavailable" {
    write_mise_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=\nexec -- herdr --version' ]
    [ ! -e "${HOME}/.agents/skills/herdr/SKILL.md" ]
}

@test "[common] run_after template bootstraps mise when it is not installed" {
    write_curl_installer_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=\nexec -- herdr --version' ]
    [ -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
}

@test "[common] run_after template updates stale mise before installing tools" {
    write_mise_stub "2026.6.12"
    write_curl_installer_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=\nexec -- herdr --version' ]
    [ -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
}

@test "[common] run_after template reuses existing GITHUB_TOKEN" {
    write_mise_stub
    write_gh_stub
    export GITHUB_TOKEN="existing-token"

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=existing-token\nexec -- herdr --version' ]
    [ ! -e "${GH_CALLS_PATH}" ]
}

@test "[common] run_after template exports gh token when GITHUB_TOKEN is unset" {
    write_mise_stub
    write_gh_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=stub-token\nexec -- herdr --version' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}

@test "[common] run_after template continues when gh token lookup fails" {
    write_mise_stub
    write_failing_gh_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=\nexec -- herdr --version' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}
