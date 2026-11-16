#!/usr/bin/env bash

# @file tests/install/common/claude_inbox_pull_fanout.sh
# @brief Verify SSH fan-out state, failure alerts, and per-machine time limits.

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
readonly REPOSITORY_ROOT
readonly SCRIPT_PATH="${REPOSITORY_ROOT}/home/private_dot_local/private_bin/exact_common/executable_claude-inbox-pull-fanout"
readonly LAUNCH_AGENT_PLIST="${REPOSITORY_ROOT}/home/private_Library/LaunchAgents/com.shunk031.claude-inbox-pull.plist.tmpl"
readonly HEAD_VALUE='0123456789abcdef0123456789abcdef01234567'
readonly REMOTE_MACHINES=(
    remote-a
    remote-b
    remote-c
    remote-d
    remote-e
)

test_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-inbox-pull-fanout.XXXXXX")"
trap 'rm -rf "${test_dir}"' EXIT

readonly state_home="${test_dir}/state"
readonly helper="${test_dir}/bin/claude-inbox-pull"
readonly queue="${test_dir}/bin/herdr-meta-patrol-queue"
readonly fake_ssh="${test_dir}/bin/ssh"
readonly fake_git="${test_dir}/bin/git"
readonly remotes_file="${test_dir}/remotes"
readonly ssh_log="${test_dir}/ssh.log"
readonly queue_log="${test_dir}/queue.log"

mkdir -p "${test_dir}/bin"
cat > "${helper}" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "${queue}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${QUEUE_LOG}"
EOF
cat > "${fake_ssh}" << 'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

arguments="$*"
[[ "${arguments}" == *'-o BatchMode=yes'* ]] || exit 90
[[ "${arguments}" == *'-o ConnectTimeout=8'* ]] || exit 91

machine=''
previous=''
for argument in "$@"; do
    previous="${machine}"
    machine="${argument}"
done
machine="${previous}"
printf '%s\t%s\n' "${machine}" "${arguments}" >> "${SSH_LOG}"

if [[ "${FAKE_SSH_MODE:-success}" == 'fail' ]]; then
    exit 255
fi
if [[ "${FAKE_SSH_SLOW_ALIAS:-}" == "${machine}" ]]; then
    sleep 10
fi
printf '%s\n' '0123456789abcdef0123456789abcdef01234567'
EOF
cat > "${fake_git}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' '0123456789abcdef0123456789abcdef01234567'
EOF
printf '%s\n' "${REMOTE_MACHINES[@]}" > "${remotes_file}"
chmod +x "${helper}" "${queue}" "${fake_ssh}" "${fake_git}"

export XDG_STATE_HOME="${state_home}"
export PATH="${test_dir}/bin:${PATH}"
export QUEUE_LOG="${queue_log}"
export SSH_LOG="${ssh_log}"
export CLAUDE_INBOX_PULL_FANOUT_SSH_COMMAND="${fake_ssh}"
export CLAUDE_INBOX_PULL_FANOUT_HELPER_COMMAND="${helper}"
export CLAUDE_INBOX_PULL_FANOUT_QUEUE_COMMAND="${queue}"
export CLAUDE_INBOX_PULL_FANOUT_MACHINE_LIST="${remotes_file}"
export CLAUDE_INBOX_PULL_FANOUT_PLUGIN_DIR="${test_dir}/plugin"

function fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

grep -Fq '/.local/bin/common/claude-inbox-pull-fanout</string>' "${LAUNCH_AGENT_PLIST}" || fail 'LaunchAgent does not run the fan-out helper'
grep -A 2 -F '<key>StartInterval</key>' "${LAUNCH_AGENT_PLIST}" | grep -Fq '<integer>300</integer>' || fail 'LaunchAgent cadence is not five minutes'

function run_fanout() {
    bash "${SCRIPT_PATH}"
}

function check_success_state() {
    local machine="$1" state_file="${state_home}/claude-inbox-pull/remotes/${1}.tsv"
    local last_success_epoch last_success_at last_head failures last_failure_at last_alert_epoch
    IFS=$'\t' read -r last_success_epoch last_success_at last_head failures last_failure_at last_alert_epoch < "${state_file}"
    [[ "${last_success_epoch}" =~ ^[0-9]+$ ]] || fail "${machine} has no success epoch"
    [[ "${last_success_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] || fail "${machine} has no success time"
    [[ "${last_head}" == "${HEAD_VALUE}" ]] || fail "${machine} has the wrong HEAD"
    [[ "${failures}" == 0 ]] || fail "${machine} retained a failure count after success"
    [[ "${last_failure_at}" == never ]] || fail "${machine} retained a failure time after success"
    [[ "${last_alert_epoch}" == 0 ]] || fail "${machine} retained an alert time after success"
}

run_fanout
check_success_state local
for machine in "${REMOTE_MACHINES[@]}"; do
    check_success_state "${machine}"
done
[[ "$(wc -l < "${ssh_log}" | tr -d '[:space:]')" == "${#REMOTE_MACHINES[@]}" ]] || fail 'not every machine was checked'

rm -rf "${state_home}" "${ssh_log}" "${queue_log}"
export CLAUDE_INBOX_PULL_FANOUT_MACHINE_LIST="${test_dir}/missing-remotes"
run_fanout
check_success_state local
[[ ! -e "${ssh_log}" ]] || fail 'fan-out attempted SSH without a private alias list'
export CLAUDE_INBOX_PULL_FANOUT_MACHINE_LIST="${remotes_file}"

rm -rf "${state_home}"
export FAKE_SSH_MODE=fail
for _ in 1 2 3; do
    run_fanout
done
[[ "$(wc -l < "${queue_log}" | tr -d '[:space:]')" == "${#REMOTE_MACHINES[@]}" ]] || fail 'three failures did not queue one alert per machine'
for machine in "${REMOTE_MACHINES[@]}"; do
    state_file="${state_home}/claude-inbox-pull/remotes/${machine}.tsv"
    IFS=$'\t' read -r last_success_epoch last_success_at last_head failures last_failure_at last_alert_epoch < "${state_file}"
    [[ "${last_success_at}" == never && "${last_head}" == never ]] || fail "${machine} recorded a success during failed checks"
    [[ "${failures}" == 3 ]] || fail "${machine} did not retain three consecutive failures"
    [[ "${last_failure_at}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] || fail "${machine} has no failure time"
    [[ "${last_alert_epoch}" =~ ^[0-9]+$ && "${last_alert_epoch}" != 0 ]] || fail "${machine} has no alert timestamp"
done
[[ "$(cat "${queue_log}")" == *'3 times in a row'* ]] || fail 'queued alert omitted the consecutive failure count'

rm -rf "${state_home}" "${ssh_log}" "${queue_log}"
unset FAKE_SSH_MODE
export FAKE_SSH_SLOW_ALIAS='remote-c'
export CLAUDE_INBOX_PULL_FANOUT_TIMEOUT_SECONDS=2
started_at="$(date +%s)"
run_fanout
elapsed=$(($(date +%s) - started_at))
((elapsed < 8)) || fail "one slow machine delayed the fan-out for ${elapsed} seconds"
check_success_state local
check_success_state 'remote-a'
slow_state="${state_home}/claude-inbox-pull/remotes/remote-c.tsv"
IFS=$'\t' read -r last_success_epoch last_success_at last_head failures last_failure_at last_alert_epoch < "${slow_state}"
[[ "${failures}" == 1 ]] || fail 'timed-out machine failure was not recorded'
[[ "${last_success_at}" == never && "${last_head}" == never ]] || fail 'timed-out machine reported a success'

printf '%s\n' 'PASS: inbox fan-out records state, alerts after repeated failures, and bounds slow hosts'
