#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_agent-github"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export TEST_LOG="${BATS_TEST_TMPDIR}/calls.txt"
    export TEST_GH_USER="shunk031"
    mkdir -p "$TEST_BIN_DIR" "$HOME"
    PATH="$TEST_BIN_DIR:$PATH"
    export PATH

    cat > "$TEST_BIN_DIR/curl" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
body="$(cat)"
case "$*" in
    *https://github.com/login/device/code*)
        printf '%s\n' '{"device_code":"device-test","user_code":"TEST-1234","verification_uri":"https://github.com/login/device","expires_in":300,"interval":1}'
        ;;
    *https://github.com/login/oauth/access_token*)
        if [[ "$body" == *'grant_type=refresh_token'* ]]; then
            printf '%s\n' 'refresh' >> "$TEST_LOG"
            printf '%s\n' '{"access_token":"ghu_refreshed","expires_in":28800,"refresh_token":"ghr_next","refresh_token_expires_in":15897600}'
        else
            printf '%s\n' 'device' >> "$TEST_LOG"
            printf '%s\n' '{"access_token":"ghu_initial","expires_in":28800,"refresh_token":"ghr_initial","refresh_token_expires_in":15897600}'
        fi
        ;;
    *) exit 1 ;;
esac
SH
    cat > "$TEST_BIN_DIR/gh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
    'api user --jq .login')
        [[ "${GH_TOKEN:-}" == ghu_* ]] || exit 1
        printf '%s\n' "$TEST_GH_USER"
        ;;
    *)
        printf 'gh:%s:%s\n' "${GH_TOKEN:-unset}" "$*" >> "$TEST_LOG"
        ;;
esac
SH
    cat > "$TEST_BIN_DIR/sleep" << 'SH'
#!/usr/bin/env bash
exit 0
SH
    chmod +x "$TEST_BIN_DIR/curl" "$TEST_BIN_DIR/gh" "$TEST_BIN_DIR/sleep"
}

function logged_in() {
    bash "$SCRIPT_PATH" login --client-id Iv1.test
}

@test "[common] agent-github Device Flow authenticates shunk031 and scopes the gh token" {
    run logged_in
    [ "$status" -eq 0 ]
    [[ "$output" == *'Authenticated as shunk031'* ]]
    [ "$(stat -c %a "$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json" 2> /dev/null || stat -f %Lp "$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json")" = '600' ]
    run bash "$SCRIPT_PATH" status
    [ "$status" -eq 0 ]
    [[ "$output" == *'App client ID: Iv1.test'* ]]
    [[ "$output" != *ghu_initial* ]]

    run env GH_TOKEN='human-token' bash "$SCRIPT_PATH" gh pr create --fill
    [ "$status" -eq 0 ]
    grep -Fqx 'gh:ghu_initial:pr create --fill' "$TEST_LOG"
}

@test "[common] agent-github refreshes its token before a GitHub write" {
    logged_in
    local state="$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json"
    jq '.expires_at = 1' "$state" > "$state.new"
    mv "$state.new" "$state"

    run bash "$SCRIPT_PATH" gh issue create --title Test
    [ "$status" -eq 0 ]
    grep -Fqx 'refresh' "$TEST_LOG"
    grep -Fqx 'gh:ghu_refreshed:issue create --title Test' "$TEST_LOG"
    [ "$(jq -r '.refresh_token' "$state")" = 'ghr_next' ]
}

@test "[common] agent-github fails closed for a different GitHub user" {
    run env TEST_GH_USER='someone-else' bash "$SCRIPT_PATH" login --client-id Iv1.test
    [ "$status" -ne 0 ]
    [[ "$output" == *'expected GitHub account shunk031, got someone-else'* ]]
    [ ! -e "$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json" ]

    run env GH_TOKEN='human-token' bash "$SCRIPT_PATH" gh pr create --fill
    [ "$status" -ne 0 ]
    ! grep -Fq 'gh:' "$TEST_LOG"
}

@test "[common] agent-github never falls back if the refresh token is unavailable" {
    logged_in
    local state="$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json"
    jq '.expires_at = 1 | .refresh_token = null' "$state" > "$state.new"
    mv "$state.new" "$state"

    run bash "$SCRIPT_PATH" gh pr comment 1 --body note
    [ "$status" -ne 0 ]
    [[ "$output" == *'no refresh token'* ]]
    ! grep -Fq 'gh:' "$TEST_LOG"
}

@test "[common] agent-github logout removes credentials and subsequent status fails" {
    logged_in
    local state="$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json"
    [ -f "$state" ]

    run bash "$SCRIPT_PATH" logout
    [ "$status" -eq 0 ]
    [ ! -e "$state" ]

    run bash "$SCRIPT_PATH" status
    [ "$status" -ne 0 ]
    [[ "$output" == *'not logged in'* ]]
}
