#!/usr/bin/env bats

readonly SCRIPT_PATH="${PWD}/home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol-feed"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export XDG_STATE_HOME="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_FEED_DIR="${BATS_TEST_TMPDIR}/feeds"
    export AGENTS_JSON="${BATS_TEST_TMPDIR}/agents.json"
    export TABS_JSON="${BATS_TEST_TMPDIR}/tabs.json"
    export GH_PR_JSON="${BATS_TEST_TMPDIR}/open-prs.json"
    export MV_LOG="${BATS_TEST_TMPDIR}/mv.log"
    REAL_MV="$(command -v mv)"
    export REAL_MV
    mkdir -p "${HERDR_META_PATROL_FEED_DIR}" "${XDG_STATE_HOME}/meta" "${BATS_TEST_TMPDIR}/bin"
    printf '[]\n' > "${GH_PR_JSON}"
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
    cat > "${BATS_TEST_TMPDIR}/bin/gh" << 'STUB'
#!/usr/bin/env bash
if [[ "${GH_FAIL:-0}" == 1 ]]; then exit 1; fi
if [[ "$1" == api ]]; then
    printf '%s\n' acme-user
elif [[ "$1" == search && "$2" == prs ]]; then
    cat "${GH_PR_JSON}"
else
    exit 2
fi
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/gh"
    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH
}

function state_snapshots() {
    printf 'Local\torch\nLocal\torch-blocked\nLocal\torch-dialog\nLocal\torch-focus\nLocal\torch-single\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    cat > "${AGENTS_JSON}" << 'JSON'
{"result":{"agents":[
  {"name":"orch","tab_id":"t-root","agent_status":"working","tokens":{"inbox":"2 · Merge release?","inbox-needs-you":"2"}},
  {"name":"orch-blocked","tab_id":"t-stop","agent_status":"idle","tokens":{"inbox":"! Usage limit reached","inbox-stop":"! Usage limit reached","inbox-needs-you":"0"}},
  {"name":"orch-dialog","tab_id":"t-dialog","agent_status":"blocked","tokens":{"inbox":"Allow command?","inbox-needs-you":"2"}},
  {"name":"orch-focus","tab_id":"t-focus","agent_status":"idle","tokens":{"inbox":"Review architecture","inbox-needs-you":"0"}},
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
  {"tab_id":"t-root","label":"🤖 Root label"},
  {"tab_id":"t-stop","label":"🤖 Root stop"},
  {"tab_id":"t-dialog","label":"🤖 Root dialog"},
  {"tab_id":"t-focus","label":"🤖 Root focus"},
  {"tab_id":"t-single","label":"🤖 Root single"},
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

    jq -e '[.entries[] | select(.key == "herdr/local/orch")][0] | .state == "working" and .title == "orch: Root label" and .detail == "2 · Merge release?"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key | startswith("herdr/local/orch/ask/"))][0] | .state == "blocked" and .title == "⛔ orch: Merge release?" and (.detail | contains("2") and contains("local") and contains("answer in that pane, or reply here for meta to relay"))' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/orch-blocked")][0] | .state == "blocked"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/orch-dialog")][0] | .state == "blocked"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/meta")][0] | .state == "blocked" and .title == "meta: Meta" and .detail == "internal ask"' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | startswith("herdr/local/orch-dialog/ask/"))] | length) == 0' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | startswith("herdr/local/orch-focus/ask/"))] | length) == 0' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key | startswith("herdr/local/orch-single/ask/"))][0] | .state == "blocked" and .title == "⛔ orch-single: Review release?"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-build")][0] | .state == "working" and .title == "worker-build: 🚧 Build feature"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-write")][0] | .state == "working" and .title == "worker-write: ✍️ Write documentation"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-stop")][0] | .state == "blocked"' "${feed}" > /dev/null
    jq -e '[.entries[] | select(.key == "herdr/local/worker/worker-done")][0] | .state == "done"' "${feed}" > /dev/null
    jq -e '([.entries[] | select(.key | contains("meta"))] | length) == 0' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed carries entries forward when a machine is unreachable" {
    state_snapshots
    bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    old_at="$(jq -r '.entries[] | select(.key == "herdr/local/orch") | .at' "${feed}")"

    run bash "${SCRIPT_PATH}" local "${BATS_TEST_TMPDIR}/missing-agents.json" "${BATS_TEST_TMPDIR}/missing-tabs.json"
    [ "${status}" -eq 0 ]
    jq -e --argjson at "${old_at}" '.entries[] | select(.key == "herdr/local/orch") | .at == $at' "${feed}" > /dev/null
    jq -e '.entries[] | select(.key == "herdr/local/_machine") | .state == "blocked" and (.detail | startswith("unreachable since "))' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed keeps an ask key when its waiting count changes" {
    state_snapshots
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    ask_key="$(jq -r '.entries[] | select(.key | startswith("herdr/local/orch/ask/")) | .key' "${feed}")"
    [ -n "${ask_key}" ]

    jq '(.result.agents[] | select(.name == "orch") | .tokens.inbox) = "3 · Merge release?"
        | (.result.agents[] | select(.name == "orch") | .tokens["inbox-needs-you"]) = "3"' "${AGENTS_JSON}" > "${AGENTS_JSON}.updated"
    mv "${AGENTS_JSON}.updated" "${AGENTS_JSON}"
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.entries[] | select(.key | startswith("herdr/local/orch/ask/")) | .key' "${feed}")" = "${ask_key}" ]
    jq -e --arg key "${ask_key}" '.entries[] | select(.key == $key) | .title == "⛔ orch: Merge release?"' "${feed}" > /dev/null
}

@test "[common] herdr-meta-patrol-feed skips an overlong key without losing other entries" {
    long_name="$(printf 'r%.0s' {1..100})"
    long_worker="$(printf 'w%.0s' {1..100})"
    printf 'Local\t%s\n' "${long_name}" > "${XDG_STATE_HOME}/meta/roots.tsv"
    jq -nc --arg name "${long_name}" --arg long_worker "${long_worker}" '{result:{agents:[{name:$name,tab_id:"long",agent_status:"working"},{name:$long_worker,tab_id:"long-worker",agent_status:"working"},{name:"worker-ok",tab_id:"ok",agent_status:"working"}]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[{tab_id:"long",label:"🤖 Long root"},{tab_id:"long-worker",label:"🚧 Long worker"},{tab_id:"ok",label:"🚧 Valid worker"}]}}' > "${TABS_JSON}"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed="${HERDR_META_PATROL_FEED_DIR}/herdr-local.json"
    jq -e '([.entries[] | select(.key == "herdr/local/worker/worker-ok")] | length) == 1' "${feed}" > /dev/null
    jq -e --arg prefix "herdr/local/${long_name}" '([.entries[] | select(.key | startswith($prefix))] | length) == 0' "${feed}" > /dev/null
    jq -e --arg prefix "herdr/local/worker/${long_worker}" '([.entries[] | select(.key | startswith($prefix))] | length) == 0' "${feed}" > /dev/null
    [[ "${output}" == *"feed key exceeds 100 bytes for ${long_name} on local"* ]]
    [[ "${output}" == *"feed key exceeds 100 bytes for worker ${long_worker} on local"* ]]
}

@test "[common] herdr-meta-patrol-feed prunes files absent from supplied snapshots" {
    state_snapshots
    touch "${HERDR_META_PATROL_FEED_DIR}/herdr-stale.json"

    run bash "${SCRIPT_PATH}" --prune local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ -f "${HERDR_META_PATROL_FEED_DIR}/herdr-local.json" ]
    [ ! -e "${HERDR_META_PATROL_FEED_DIR}/herdr-stale.json" ]
}

@test "[common] herdr-meta-patrol-feed keeps blocked entries first at the 40-entry limit" {
    jq -nc '{result:{agents:[range(0;45) as $i | {name:("worker-" + ($i|tostring)),tab_id:("tab-" + ($i|tostring)),agent_status:"working"}]}}' > "${AGENTS_JSON}"
    jq -nc '{result:{tabs:[range(0;45) as $i | {tab_id:("tab-" + ($i|tostring)),label:(if $i < 10 then "⛔ Blocked" elif $i < 40 then "🚧 Working" else "✅ Done" end)}]}}' > "${TABS_JSON}"

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

@test "[common] herdr-meta-patrol-feed indexes open PRs from every author and clears closed PRs" {
    cat > "${GH_PR_JSON}" << 'JSON'
[
  {"number":12,"title":"A skills change","isDraft":false,"url":"https://github.com/acme-user/skills/pull/12","author":{"login":"acme-user"},"repository":{"nameWithOwner":"acme-user/skills"}},
  {"number":83,"title":"A dependency update","isDraft":true,"url":"https://github.com/acme-user/dotfiles/pull/83","author":{"login":"renovate[bot]"},"repository":{"nameWithOwner":"acme-user/dotfiles"}}
]
JSON

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    skills_feed="${HERDR_META_PATROL_FEED_DIR}/github-prs-acme-user-skills-0.json"
    dotfiles_feed="${HERDR_META_PATROL_FEED_DIR}/github-prs-acme-user-dotfiles-0.json"
    jq -e '.source == "github-open-prs" and .entries[0].key == "github/pr/12" and (.entries[0].detail | contains("https://github.com/acme-user/skills/pull/12"))' "${skills_feed}" > /dev/null
    jq -e '.entries[0].title | startswith("acme-user/dotfiles#83")' "${dotfiles_feed}" > /dev/null
    jq -e '.entries[0].detail | startswith("Draft · renovate[bot]")' "${dotfiles_feed}" > /dev/null

    previous_skills_feed="$(cat "${skills_feed}")"
    export GH_FAIL=1
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${skills_feed}")" = "${previous_skills_feed}" ]
    unset GH_FAIL

    printf '[]\n' > "${GH_PR_JSON}"
    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    [ "$(jq '.entries | length' "${skills_feed}")" -eq 0 ]
    [ "$(jq '.entries | length' "${dotfiles_feed}")" -eq 0 ]
}

@test "[common] herdr-meta-patrol-feed splits a repository with more than 40 open PRs" {
    jq -nc '[range(1;42) as $n | {number:$n,title:("PR " + ($n | tostring)),isDraft:false,url:("https://github.com/acme-user/large/pull/" + ($n | tostring)),author:{login:"acme-user"},repository:{nameWithOwner:"acme-user/large"}}]' > "${GH_PR_JSON}"

    run bash "${SCRIPT_PATH}" local "${AGENTS_JSON}" "${TABS_JSON}"
    [ "${status}" -eq 0 ]
    feed_zero="${HERDR_META_PATROL_FEED_DIR}/github-prs-acme-user-large-0.json"
    feed_one="${HERDR_META_PATROL_FEED_DIR}/github-prs-acme-user-large-1.json"
    [ "$(jq '.entries | length' "${feed_zero}")" -eq 40 ]
    [ "$(jq '.entries | length' "${feed_one}")" -eq 1 ]
}
