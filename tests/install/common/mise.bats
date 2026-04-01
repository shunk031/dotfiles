#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl"
readonly DOT_NPMRC_PATH="./home/dot_npmrc"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
}

function teardown() {
    if [ -e "${MISE_INSTALL_PATH}" ]; then
        uninstall_mise
    fi

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

function get_min_release_age_days() {
    awk -F= '
        $1 ~ /^[[:space:]]*min-release-age[[:space:]]*$/ {
            gsub(/[[:space:]]/, "", $2)
            print $2
            exit
        }
    ' "${1}"
}

@test "[common] mise" {
    [ -e "${TMPL_SCRIPT_PATH}" ]

    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.local/bin"
    [ -x "$(command -v mise)" ]
}

@test "[common] npm min-release-age matches mise default days" {
    [ -e "${DOT_NPMRC_PATH}" ]

    expected_days="$(get_min_release_age_days "${DOT_NPMRC_PATH}")"
    [ -n "${expected_days}" ]
    [ "${DEFAULT_NPM_MIN_RELEASE_AGE_DAYS}" = "${expected_days}" ]
}

@test "[common] run_mise_install uses min-release-age days from npmrc" {
    expected_days="$(get_min_release_age_days "${DOT_NPMRC_PATH}")"
    [ -n "${expected_days}" ]

    printf "min-release-age=%s\n" "${expected_days}" > "${HOME}/.npmrc"

    function mise() {
        echo "$*" > "${BATS_TEST_TMPDIR}/mise_install_args.txt"
    }

    run_mise_install

    run cat "${BATS_TEST_TMPDIR}/mise_install_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "install --before ${expected_days}d" ]
}
