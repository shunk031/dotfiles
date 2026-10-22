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
            if [[ "${TEST_ROTATING_TOKENS:-0}" == 1 ]]; then
                token_count=0
                [[ ! -f "$TEST_TOKEN_COUNT" ]] || read -r token_count < "$TEST_TOKEN_COUNT"
                token_count=$((token_count + 1))
                printf '%s\n' "$token_count" > "$TEST_TOKEN_COUNT"
                printf 'refresh:%s\n' "$token_count" >> "$TEST_LOG"
                if ((token_count == 1)); then
                    printf '%s\n' '{"access_token":"ghu_first","expires_in":60,"refresh_token":"ghr_next","refresh_token_expires_in":15897600}'
                else
                    : > "$TEST_TOKEN_INVALIDATED"
                    printf '%s\n' '{"access_token":"ghu_second","expires_in":28800,"refresh_token":"ghr_next","refresh_token_expires_in":15897600}'
                fi
            else
                printf '%s\n' 'refresh' >> "$TEST_LOG"
                printf '%s\n' '{"access_token":"ghu_refreshed","expires_in":28800,"refresh_token":"ghr_next","refresh_token_expires_in":15897600}'
            fi
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
        if [[ "${TEST_PROCESS:-}" == first && "${TEST_PAUSE_FIRST_GH:-0}" == 1 ]]; then
            : > "$TEST_FIRST_GH_ENTERED"
            while [[ ! -e "$TEST_RELEASE_FIRST_GH" ]]; do /bin/sleep 0.05; done
        fi
        if [[ "${GH_TOKEN:-}" == ghu_first && -n "${TEST_TOKEN_INVALIDATED:-}" && -e "$TEST_TOKEN_INVALIDATED" ]]; then
            exit 1
        fi
        printf 'gh:%s:%s\n' "${GH_TOKEN:-unset}" "$*" >> "$TEST_LOG"
        ;;
esac
SH
    cat > "$TEST_BIN_DIR/sleep" << 'SH'
#!/usr/bin/env bash
if [[ "${TEST_PROCESS:-}" == second ]]; then
    printf '%s\n' 'second-wait' >> "$TEST_LOG"
    /bin/sleep 0.05
fi
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

@test "[common] agent-github holds the lock until an active gh command finishes" {
    logged_in
    local state="$XDG_CONFIG_HOME/shunk031-agent-bot/auth.json"
    local first_pid second_pid first_status=0 second_status=0
    local attempt=0 invalidated_before_release=0 second_wait_observed=0
    local invalidated="$BATS_TEST_TMPDIR/token-invalidated"
    local token_count="$BATS_TEST_TMPDIR/token-count"
    local entered="$BATS_TEST_TMPDIR/first-gh-entered"
    local release="$BATS_TEST_TMPDIR/release-first-gh"
    jq '.expires_at = 1' "$state" > "$state.new"
    mv "$state.new" "$state"

    env TEST_ROTATING_TOKENS=1 TEST_PROCESS=first TEST_PAUSE_FIRST_GH=1 \
        TEST_TOKEN_COUNT="$token_count" TEST_TOKEN_INVALIDATED="$invalidated" \
        TEST_FIRST_GH_ENTERED="$entered" TEST_RELEASE_FIRST_GH="$release" \
        bash "$SCRIPT_PATH" gh issue create --title first &
    first_pid=$!
    while [[ ! -e "$entered" ]] && ((attempt < 100)); do
        /bin/sleep 0.05
        attempt=$((attempt + 1))
    done
    if [[ ! -e "$entered" ]]; then
        : > "$release"
        wait "$first_pid" || true
        return 1
    fi

    env TEST_ROTATING_TOKENS=1 TEST_PROCESS=second \
        TEST_TOKEN_COUNT="$token_count" TEST_TOKEN_INVALIDATED="$invalidated" \
        TEST_FIRST_GH_ENTERED="$entered" TEST_RELEASE_FIRST_GH="$release" \
        bash "$SCRIPT_PATH" gh issue create --title second &
    second_pid=$!
    attempt=0
    while ! grep -Fqx 'second-wait' "$TEST_LOG" && [[ ! -e "$invalidated" ]] && ((attempt < 100)); do
        /bin/sleep 0.05
        attempt=$((attempt + 1))
    done
    if grep -Fqx 'second-wait' "$TEST_LOG"; then
        second_wait_observed=1
    fi
    [[ ! -e "$invalidated" ]] || invalidated_before_release=1
    : > "$release"
    wait "$first_pid" || first_status=$?
    wait "$second_pid" || second_status=$?

    [ "$second_wait_observed" -eq 1 ]
    [ "$invalidated_before_release" -eq 0 ]
    [ "$first_status" -eq 0 ]
    [ "$second_status" -eq 0 ]
    grep -Fqx 'gh:ghu_first:issue create --title first' "$TEST_LOG"
    grep -Fqx 'gh:ghu_second:issue create --title second' "$TEST_LOG"
    grep -Fqx 'refresh:1' "$TEST_LOG"
    grep -Fqx 'refresh:2' "$TEST_LOG"
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
