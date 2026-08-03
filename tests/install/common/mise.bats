#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"
readonly TMPL_SCRIPT_GLOB="./home/.chezmoiscripts/common/run_once_after_*-install-mise.sh.tmpl"
readonly RUN_AFTER_TEMPLATE="./home/.chezmoiscripts/common/run_after_20-install-mise-tools.sh.tmpl"
readonly MISE_CONFIG_SOURCE="./home/dot_mise/config.toml"
readonly MISE_BASH_SOURCE="./home/dot_config/exact_shell/mise.bash"

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
    export GH_CALLS_PATH="${BATS_TEST_TMPDIR}/gh_calls.txt"
    export MISE_CONFIG_PATH="${BATS_TEST_TMPDIR}/mise_config.toml"
    export RUN_AFTER_SCRIPT="${BATS_TEST_TMPDIR}/run_after_20-install-mise-tools.sh"
    export BATS_TEST_TMPDIR
    PATH="${TEST_BIN_DIR}:$(getconf PATH)"
    export PATH

    mkdir -p "${HOME}/.local/bin" "${TEST_BIN_DIR}"
    rm -f \
        "${MISE_CALLS_PATH}" \
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

function write_mise_stub() {
    local version="${1:-2026.6.13}"

    cat > "${MISE_INSTALL_PATH}" << EOF
#!/usr/bin/env bash

case "\$1" in
    --version)
        printf 'mise ${version}\\n'
        ;;
    activate)
        if [ "\${2:-}" = "bash" ] && [ "\${3:-}" = "--shims" ]; then
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

@test "[common] mise config declares a parseable top-level min_version" {
    run get_mise_min_version_from_config "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
    [[ "${output}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]
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

@test "[common] Codex CLI is pinned and exempt from mise release age" {
    run grep -F '"aqua:openai/codex" = "0.145.0"' "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]

    run grep -F '"aqua:openai/codex",' "${MISE_CONFIG_SOURCE}"
    [ "${status}" -eq 0 ]
}

@test "[common] run_after template installs pinned mise tools after apply" {
    write_mise_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
}

@test "[common] run_after template bootstraps mise when it is not installed" {
    write_curl_installer_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
    [ -e "${BATS_TEST_TMPDIR}/curl_args.txt" ]
}

@test "[common] run_after template updates stale mise before installing tools" {
    write_mise_stub "2026.6.12"
    write_curl_installer_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
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
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=existing-token' ]
    [ ! -e "${GH_CALLS_PATH}" ]
}

@test "[common] run_after template exports gh token when GITHUB_TOKEN is unset" {
    write_mise_stub
    write_gh_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=stub-token' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}

@test "[common] run_after template continues when gh token lookup fails" {
    write_mise_stub
    write_failing_gh_stub

    run bash "${RUN_AFTER_SCRIPT}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install\nMISE_CURRENT_VERSION=\nMISE_VERSION=\nGITHUB_TOKEN=' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}
