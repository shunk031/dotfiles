#!/usr/bin/env bats

readonly SCRIPT_PATH="${PWD}/home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol-feed"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export XDG_STATE_HOME="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_FEED_DIR="${BATS_TEST_TMPDIR}/feeds"
    export AGENTS_JSON="${BATS_TEST_TMPDIR}/agents.json"
    export TABS_JSON="${BATS_TEST_TMPDIR}/tabs.json"
    export MV_LOG="${BATS_TEST_TMPDIR}/mv.log"
    REAL_MV="$(command -v mv)"
    export REAL_MV
    mkdir -p "${HERDR_META_PATROL_FEED_DIR}" "${XDG_STATE_HOME}/meta" "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/mv" << 'STUB'
#!/usr/bin/env bash
if [[ "$1" == -f ]]; then
    printf '%s\t%s\n' "$2" "$3" >> "${MV_LOG}"
else
    printf '%s\t%s\n' "$1" "$2" >> "${MV_LOG}"
fi
exec "${REAL_MV}" "$@"
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/mv"
    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH
}

function state_snapshots() {
    printf 'Local\torch\nLocal\torch-blocked\nLocal\torch-dialog\nLocal\torch-focus\nLocal\tmeta\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    cat > "${AGENTS_JSON}" << 'JSON'
{"result":{"agents":[
  {"name":"orch","tab_id":"t-root","agent_status":"working","tokens":{"inbox":"2 · Merge release?","inbox-needs-you":"2"}},
  {"name":"orch-blocked","tab_id":"t-stop","agent_status":"idle","tokens":{"inbox":"! Usage limit reached","inbox-stop":"! Usage limit reached","inbox-needs-you":"0"}},
  {"name":"orch-dialog","tab_id":"t-dialog","agent_status":"blocked","tokens":{"inbox":"Allow command?"}},
  {"name":"orch-focus","tab_id":"t-focus","agent_status":"idle","tokens":{"inbox":"Review architecture","inbox-needs-you":"0"}},
  {"name":"worker-build","tab_id":"t-build","agent_status":"working","tokens":{"inbox":"Build the feature"}},
  {"name":"worker-write","tab_id":"t-write","agent_status":"working"},
  {"name":"worker-stop","tab_id":"t-stop-worker","agent_status":"blocked"},
  {"name":"worker-done","tab_id":"t-done","agent_status":"done"},
  {"name":"meta","tab_id":"t-meta","agent_status":"blocked","tokens":{"inbox":"internal ask"}}
]}}
JSON
    cat > "${TABS_JSON}" << 'JSON'
{"result":{"tabs":[
  {"tab_id":"t-root","label":"🤖 Root label"},
  {"tab_id":"t-stop","label":"🤖 Root stop"},
  {"tab_id":"t-dialog","label":"🤖 Root dialog"},
  {"tab_id":"t-focus","label":"🤖 Root focus"},
  {"tab_id":"t-build","label":"🚧 Build feature"},
  {"tab_id":"t-write","label":"✍️ Write documentation"},
  {"tab_id":"t-stop-worker","label":"⛔ Waiting for review"},
  {"tab_id":"t-done","label":"✅ Finished"},
  {"tab_id":"t-meta","label":"🤖 Meta"}
]}}
JSON
}

@test "[common] herdr-meta-patrol-feed maps roots and worker labels and detects asks by count token" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"

    jq -e '[.entries[] | select(.key == "herdr/local/orch")][0] | .state == "working" and .title == "orch: Root label" and .detail == "2 · Merge release?"' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key | startswith("herdr/local/orch/ask/"))][0] | .state == "blocked" and .title == "⛔ orch: Merge release?" and (.detail | contains("2") and contains("local") and contains("answer in that pane, or reply here for meta to relay"))' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/orch-blocked")][0] | .state == "blocked"' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/orch-dialog")][0] | .state == "blocked"' "${feed}" >/dev/null
    ! jq -e '.entries[] | select(.key | startswith("herdr/local/orch-focus/ask/"))' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-build")][0] | .state == "working" and .title == "worker-build: 🚧 Build feature"' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-write")][0] | .state == "working" and .title == "worker-write: ✍️ Write documentation"' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-stop")][0] | .state == "blocked"' "${feed}" >/dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-done")][0] | .state == "done"' "${feed}" >/dev/null
    ! jq -e '.entries[] | select(.key | contains("meta"))' "${feed}" >/dev/null
}

@test "[common] herdr-meta-patrol-feed carries entries forward when a machine is unreachable" {
    state_snapshots
    bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    old_at="$(jq -r '.entries[] | select(.key == "herdr/local/orch") | .at' "${feed}")"

    run bash "${SCRIPT_PATH}" local "${BATS_TEST_TMPDIR}/missing-agents.json" "${BATS_TEST_TMPDIR}/missing-tabs.json"
    [ "${status}" -eq 0 ]
    jq -e --argjson at "${old_at}" '.entries[] | select(.key == "herdr/local/orch") | .at == $at' "${feed}" >/dev/null
    jq -e '.entries[] | select(.key == "herdr/local/_machine") | .state == "blocked" and (.detail | startswith("unreachable since "))' "${feed}" >/dev/null
}

@test "[common] herdr-meta-patrol-feed keeps blocked entries first at the 40-entry limit" {
    jq -nc '{result:{agents:[range(0;45) as $i | {name:("worker-" + ($i|tostring)),tab_id:("tab-" + ($i|tostring)),agent_status:"working"}]}}' > "${AGENTS_JSON}"
    jq -c '{result:{tabs:[range(0;45) as $i | {tab_id:("tab-" + ($i|tostring)),label:(if $i < 10 then "⛔ Blocked" elif $i < 40 then "🚧 Working" else "✅ Done" end)}]}}' > "${TABS_JSON}"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    [ "$(jq '.entries | length' "${feed}")" -eq 40 ]
    [ "$(jq '[.entries[] | select(.state == "blocked")] | length' "${feed}")" -eq 10 ]
    [ "$(jq '[.entries[] | select(.state == "working")] | length' "${feed}")" -eq 30 ]
    [ "$(jq '[.entries[] | select(.state == "done")] | length' "${feed}")" -eq 0 ]
}

@test "[common] herdr-meta-patrol-feed uses a same-directory dot temp without a JSON suffix" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    IFS=$'\t' read -r temp destination < "${MV_LOG}"
    [ "${temp%/*}" = "${HERDR_META_PATROL_FEED_DIR}" ]
    [[ "${temp##*/}" == .tmp.* ]]
    [[ "${temp}" != *'.json'* ]]
    [ "${destination}" = "${HERDR_META_PATROL_FEED_DIR}/herdr-local.json" ]
}

@test "[common] herdr-meta-patrol-feed does not rewrite an unchanged feed" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ "$(wc -l < "${MV_LOG}" | tr -d '[:space:]')" -eq 1 ]
}
