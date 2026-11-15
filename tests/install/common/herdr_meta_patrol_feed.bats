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
    printf 'Local\torch\nLocal\torch\nLocal\torch-blocked\nLocal\torch-blocked-no-ask\nLocal\torch-dialog\nLocal\torch-focus\nLocal\torch-needs-you\nLocal\torch-noninteger\nLocal\torch-stop-zero\nLocal\torch-idle\nLocal\torch-done\nLocal\torch-single\nLocal\tmeta\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    cat > "${AGENTS_JSON}" << 'JSON'
{"result":{"agents":[
  {"name":"orch","tab_id":"t-root","agent_status":"working","tokens":{"inbox":"2 · Merge release?","inbox-needs-you":"2"}},
  {"name":"orch-blocked","tab_id":"t-stop","agent_status":"idle","tokens":{"inbox":"Status detail · 4 findings","inbox-stop":"! Usage limit reached","inbox-needs-you":"0"}},
  {"name":"orch-blocked-no-ask","tab_id":"t-blocked-no-ask","agent_status":"blocked"},
  {"name":"orch-dialog","tab_id":"t-dialog","agent_status":"blocked","tokens":{"inbox":"Allow command?","inbox-needs-you":"2"}},
  {"name":"orch-focus","tab_id":"t-focus","agent_status":"idle","tokens":{"inbox":"4 findings","inbox-needs-you":"0"}},
  {"name":"orch-needs-you","tab_id":"t-needs-you","agent_status":"idle","tokens":{"inbox":"Review architecture","inbox-needs-you":"2"}},
  {"name":"orch-noninteger","tab_id":"t-noninteger","agent_status":"idle","tokens":{"inbox":"Invalid count","inbox-needs-you":"1.5"}},
  {"name":"orch-stop-zero","tab_id":"t-stop-zero","agent_status":"idle","tokens":{"inbox":"2 findings","inbox-stop":"0","inbox-needs-you":"0"}},
  {"name":"orch-idle","tab_id":"t-idle","agent_status":"idle"},
  {"name":"orch-done","tab_id":"t-done-root","agent_status":"done"},
  {"name":"orch-single","tab_id":"t-single","agent_status":"working","tokens":{"inbox":"Review release?","inbox-needs-you":"1"}},
  {"name":"worker-build","tab_id":"t-build","agent_status":"working","tokens":{"inbox":"Build the feature"}},
  {"name":"worker-write","tab_id":"t-write","agent_status":"working"},
  {"name":"worker-stop","tab_id":"t-stop-worker","agent_status":"blocked"},
  {"name":"worker-done","tab_id":"t-done","agent_status":"done"},
  {"name":"meta","tab_id":"t-meta","agent_status":"blocked","tokens":{"inbox":"internal ask"}}
]}}
JSON
    cat > "${TABS_JSON}" << 'JSON'
{"result":{"tabs":[
  {"tab_id":"t-root","label":"✅ Incorrectly finished"},
  {"tab_id":"t-stop","label":"🤖 Root stop"},
  {"tab_id":"t-blocked-no-ask","label":"🤖 Root blocked"},
  {"tab_id":"t-dialog","label":"🤖 Root dialog"},
  {"tab_id":"t-focus","label":"🤖 Root focus"},
  {"tab_id":"t-needs-you","label":"🤖 Root needs you"},
  {"tab_id":"t-noninteger","label":"🤖 Root fractional count"},
  {"tab_id":"t-stop-zero","label":"🤖 Root zero stop"},
  {"tab_id":"t-idle","label":"🤖 Root idle"},
  {"tab_id":"t-done-root","label":"🤖 Root done"},
  {"tab_id":"t-single","label":"🤖 Root single"},
  {"tab_id":"t-build","label":"🚧 Build feature"},
  {"tab_id":"t-write","label":"✍️ Write documentation"},
  {"tab_id":"t-stop-worker","label":"⛔ Waiting for review"},
  {"tab_id":"t-done","label":"✅ Finished"},
  {"tab_id":"t-meta","label":"🤖 Meta"}
]}}
JSON
}

@test "[common] herdr-meta-patrol-feed emits registered roots and warns about untracked asks" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"

    jq -e '([.entries[] | select(.key | startswith("herdr/local/root/"))] | length) == 7' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/orch")][0] | .state == "working" and .title == "orch: working" and .detail == "2 · Merge release?"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/orch-blocked")][0] | .state == "blocked" and .detail == "Status detail · 4 findings"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/orch-blocked-no-ask")][0] | .state == "blocked"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/orch-dialog")][0] | .state == "blocked" and .detail == "Allow command?"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/orch-needs-you")][0] | .state == "done" and .detail == "Review architecture"' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key == "herdr/local/root/orch-focus" or .key == "herdr/local/root/orch-noninteger" or .key == "herdr/local/root/orch-stop-zero" or .key == "herdr/local/root/orch-idle" or .key == "herdr/local/root/orch-done")] | length) == 0' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/root/meta")][0] | .state == "blocked" and .detail == "internal ask"' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | startswith("herdr/local/worker/"))] | length) == 0' "${feed}" > /dev/null
    jq -e '[.warnings[] | select(.key == "herdr/local/orch/untracked-asks")][0] | .title == "orch: user asks" and (.detail | contains("2 of 2 asks"))' "${feed}" > /dev/null
    jq -e '[.warnings[] | select(.key == "herdr/local/orch-dialog/untracked-asks")][0] | .detail | contains("2 of 2 asks")' "${feed}" > /dev/null
    jq -e '[.warnings[] | select(.key == "herdr/local/orch-needs-you/untracked-asks")][0] | .detail | contains("2 of 2 asks")' "${feed}" > /dev/null
    jq -e '([.warnings[] | select(.key == "herdr/local/orch-focus/untracked-asks")] | length) == 0' "${feed}" > /dev/null
    jq -e '[.warnings[] | select(.key == "herdr/local/orch-single/untracked-asks")][0] | .detail | contains("1 of 1 asks")' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed carries entries forward when a machine is unreachable" {
    state_snapshots
    bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    old_at="$(jq -r '.entries[] | select(.key == "herdr/local/root/orch") | .at' "${feed}")"

    run bash "${SCRIPT_PATH}" local "${BATS_TEST_TMPDIR}/missing-agents.json" "${BATS_TEST_TMPDIR}/missing-tabs.json"
    [ "${status}" -eq 0 ]
    jq -e --argjson at "${old_at}" '.entries[] | select(.key == "herdr/local/root/orch") | .at == $at' "${feed}" > /dev/null
    jq -e '.entries[] | select(.key == "herdr/local/_machine") | .state == "blocked" and (.detail | startswith("unreachable since "))' "${feed}" > /dev/null
    jq -e '.warnings[] | select(.key == "herdr/local/orch/untracked-asks")' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed keeps a root warning key and updates its unmatched count" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    warning_key="$(jq -r '.warnings[] | select(.key == "herdr/local/orch/untracked-asks") | .key' "${feed}")"
    [ -n "${warning_key}" ]

    jq '(.result.agents[] | select(.name == "orch") | .tokens.inbox) = "3 · Merge release?"
        | (.result.agents[] | select(.name == "orch") | .tokens["inbox-needs-you"]) = "3"' "${AGENTS_JSON}" > "${AGENTS_JSON}.updated"
    mv "${AGENTS_JSON}.updated" "${AGENTS_JSON}"
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.warnings[] | select(.key == "herdr/local/orch/untracked-asks") | .key' "${feed}")" = "${warning_key}" ]
    jq -e --arg key "${warning_key}" '.warnings[] | select(.key == $key) | .detail | contains("3 of 3 asks")' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed warns only for meta workers and user asks with no matching source items" {
    printf 'Local\torch\nLocal\torch-signal\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    jq -nc '{result:{agents:[
        {name:"meta-build",agent_status:"working"},
        {name:"meta-blocked",agent_status:"blocked"},
        {name:"meta-idle",agent_status:"idle"},
        {name:"orch",agent_status:"working",tokens:{"inbox-needs-you":"2"}},
        {name:"orch-signal",agent_status:"working",tokens:{"inbox-needs-you":"1"}}
    ]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[]}}' > "${TABS_JSON}"
    jq -nc '{version:1,source:"meta-open-items",writtenAt:1,entries:[
        {key:"work/build",kind:"work",state:"working",title:"Build",detail:"",at:1,owner:{machine:"local",agent:"meta-build"}},
        {key:"task/review",kind:"task",state:"blocked",title:"Review",detail:"",at:1,owner:{machine:"local",agent:"orch"}},
        {key:"task/signal",kind:"task",state:"working",title:"Signal task",detail:"",at:1,signalKey:"herdr/local/orch-signal/untracked-asks"}
    ]}' > "${HERDR_META_PATROL_FEED_DIR}/meta-open-items.json"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    jq -e '([.warnings[] | select(.key == "herdr/local/meta-build/untracked-work")] | length) == 0' "${feed}" > /dev/null
    jq -e '.warnings[] | select(.key == "herdr/local/meta-blocked/untracked-work") | .detail | contains("blocked")' "${feed}" > /dev/null
    jq -e '([.warnings[] | select(.key == "herdr/local/meta-idle/untracked-work")] | length) == 0' "${feed}" > /dev/null
    jq -e '.warnings[] | select(.key == "herdr/local/orch/untracked-asks") | .detail | contains("1 of 2 asks")' "${feed}" > /dev/null
    jq -e '([.warnings[] | select(.key == "herdr/local/orch-signal/untracked-asks")] | length) == 0' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | contains("meta-build"))] | length) == 0' "${feed}" > /dev/null

    jq '.result.agents |= map(if .name == "orch" then .tokens["inbox-needs-you"] = "0" else . end | select(.name != "meta-blocked"))' "${AGENTS_JSON}" > "${AGENTS_JSON}.updated"
    mv "${AGENTS_JSON}.updated" "${AGENTS_JSON}"
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    jq -e '(.warnings | length) == 0' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed skips an overlong key without losing other entries" {
    long_name="$(printf 'r%.0s' {1..100})"
    long_worker="$(printf 'w%.0s' {1..100})"
    printf 'Local\t%s\n' "${long_name}" > "${XDG_STATE_HOME}/meta/roots.tsv"
    jq -nc --arg name "${long_name}" --arg long_worker "${long_worker}" '{result:{agents:[{name:$name,tab_id:"long",agent_status:"working",tokens:{"inbox-needs-you":"1"}},{name:$long_worker,tab_id:"long-worker",agent_status:"working"},{name:"worker-ok",tab_id:"ok",agent_status:"working"}]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[{tab_id:"long",label:"🤖 Long root"},{tab_id:"long-worker",label:"🚧 Long worker"},{tab_id:"ok",label:"🚧 Valid worker"}]}}' > "${TABS_JSON}"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    jq -e --arg prefix "herdr/local/root/${long_name}" '([.entries[] | select(.key | startswith($prefix))] | length) == 0' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | startswith("herdr/local/worker/"))] | length) == 0' "${feed}" > /dev/null
    [[ "${output}" == *"warning key exceeds 100 bytes for root ${long_name}"* ]]
    [[ "${output}" == *"feed key exceeds 100 bytes for root ${long_name} on local"* ]]
}

@test "[common] herdr-meta-patrol-feed prunes files absent from supplied snapshots" {
    state_snapshots
    touch "${HERDR_META_PATROL_FEED_DIR}/herdr-stale.json"

    run bash "${SCRIPT_PATH}" --prune local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ -f "${HERDR_META_PATROL_FEED_DIR}/herdr-local.json" ]
    [ ! -e "${HERDR_META_PATROL_FEED_DIR}/herdr-stale.json" ]
}

@test "[common] herdr-meta-patrol-feed keeps blocked roots first at the 40-entry limit" {
    jq -nc '{result:{agents:[range(0;45) as $i | {name:("root-" + ($i|tostring)),agent_status:(if $i < 10 then "blocked" elif $i < 40 then "working" else "done" end)}]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[]}}' > "${TABS_JSON}"
    jq -nr '[range(0;45) as $i | "Local\troot-\($i)"] | .[]' > "${XDG_STATE_HOME}/meta/roots.tsv"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    [ "$(jq '.entries | length' "${feed}")" -eq 40 ]
    [ "$(jq '[.entries[] | select(.state == "blocked")] | length' "${feed}")" -eq 10 ]
    [ "$(jq '[.entries[] | select(.state == "working")] | length' "${feed}")" -eq 30 ]
    [ "$(jq '[.entries[] | select(.state == "done")] | length' "${feed}")" -eq 0 ]
}

@test "[common] herdr-meta-patrol-feed keeps every live-work warning" {
    jq -nc '{result:{agents:[range(0;45) as $i | {name:("meta-worker-" + ($i|tostring)),agent_status:"working"}]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[]}}' > "${TABS_JSON}"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    [ "$(jq '.warnings | length' "${feed}")" -eq 45 ]
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
