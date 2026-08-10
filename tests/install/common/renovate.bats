#!/usr/bin/env bats

readonly RENOVATE_CONFIG_PATH="./.github/renovate.json"
readonly DEPENDABOT_CONFIG_PATH="./.github/dependabot.yaml"
readonly MISE_CONFIG_PATH="./home/dot_mise/config.toml"
readonly UBUNTU_WORKFLOW_PATH="./.github/workflows/ubuntu.yaml"
readonly MACOS_WORKFLOW_PATH="./.github/workflows/macos.yaml"
readonly AGENTS_PATH="./AGENTS.md"

@test "[common] Renovate exclusively manages GitHub Actions updates" {
    run python3 - "${RENOVATE_CONFIG_PATH}" "${DEPENDABOT_CONFIG_PATH}" << 'PYTHON'
import json
import sys
from pathlib import Path

renovate_path, dependabot_path = map(Path, sys.argv[1:])
renovate = json.loads(renovate_path.read_text(encoding="utf-8"))

rules = renovate["packageRules"]
group_rule = next(
    rule
    for rule in rules
    if rule.get("groupName") == "GitHub Actions"
)
patch_rule = next(
    rule
    for rule in rules
    if rule.get("matchManagers") == ["github-actions"]
    and rule.get("matchUpdateTypes") == ["patch"]
)

assert not dependabot_path.exists()
assert group_rule["matchManagers"] == ["github-actions"]
assert group_rule["matchUpdateTypes"] == ["minor", "major"]
assert patch_rule["enabled"] is False
PYTHON

    [ "${status}" -eq 0 ]
}

@test "[common] Renovate tracks the configured agent dependencies" {
    run python3 - "${RENOVATE_CONFIG_PATH}" "${MISE_CONFIG_PATH}" << 'PYTHON'
import json
import re
import sys
from pathlib import Path

renovate_path, mise_path = map(Path, sys.argv[1:])
renovate = json.loads(renovate_path.read_text(encoding="utf-8"))
mise_text = mise_path.read_text(encoding="utf-8")
renovate_text = json.dumps(renovate)

expected_dep_names = [
    "fnox",
    "herdr",
    "aqua:anthropics/claude-code",
    "aqua:google-antigravity/antigravity-cli",
    "aqua:openai/codex",
    "github:router-for-me/CLIProxyAPI",
]
logical_names = {name.split("/")[-1] for name in expected_dep_names}
configured_dep_names = {
    match.group("name")
    for match in re.finditer(
        r'^\s*"?(?P<name>[^"\s=]+)"?\s*=\s*(?:"|\{)',
        mise_text,
        re.MULTILINE,
    )
    if match.group("name").split("/")[-1] in logical_names
}
configured_agents = {name.split("/")[-1]: name for name in configured_dep_names}

rules = renovate["packageRules"]
agent_rule_index, agent_rule = next(
    (index, rule)
    for index, rule in enumerate(rules)
    if rule.get("groupName") == "agent tooling"
)
mise_rule_index = next(
    index
    for index, rule in enumerate(rules)
    if rule.get("groupName") == "mise tools"
)
codex_rule = next(
    rule
    for rule in rules
    if rule.get("matchManagers") == ["mise"]
    and rule.get("matchDepNames") == ["aqua:openai/codex"]
    and "extractVersion" in rule
)

assert configured_dep_names == set(expected_dep_names)
assert configured_agents["fnox"] == "fnox"
assert configured_agents["claude-code"].startswith("aqua:")
assert configured_agents["antigravity-cli"].startswith("aqua:")
assert configured_agents["codex"].startswith("aqua:")
assert configured_agents["CLIProxyAPI"].startswith("github:")
assert agent_rule["matchManagers"] == ["mise"]
assert agent_rule["matchDepNames"] == expected_dep_names
assert agent_rule["minimumReleaseAge"] == "0 days"
assert mise_rule_index < agent_rule_index

assert "matchPackageNames" not in agent_rule
assert "npm:@anthropic-ai/claude-code" not in renovate_text
assert "npm:@openai/codex" not in renovate_text

assert codex_rule["matchManagers"] == ["mise"]
assert codex_rule["matchDepNames"] == ["aqua:openai/codex"]
python_pattern = codex_rule["extractVersion"].replace("(?<version>", "(?P<version>")
match = re.fullmatch(python_pattern, "rust-v0.146.0")
assert match is not None
assert match.group("version") == "0.146.0"
PYTHON

    [ "${status}" -eq 0 ]
}

@test "[common] Renovate does not raise the minimum compatible mise version" {
    run python3 - "${RENOVATE_CONFIG_PATH}" << 'PYTHON'
import json
import sys
from pathlib import Path

renovate = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
custom_managers = renovate.get("customManagers", [])
package_rules = renovate["packageRules"]

assert all("min_version" not in json.dumps(manager) for manager in custom_managers)
assert not any(
    rule.get("matchManagers") == ["custom.regex"]
    and rule.get("matchPackageNames") == ["jdx/mise"]
    for rule in package_rules
)
assert not any(rule.get("groupName") == "mise bootstrap" for rule in package_rules)
PYTHON

    [ "${status}" -eq 0 ]
}

@test "[common] mise changes trigger fresh-install workflows" {
    run python3 - "${UBUNTU_WORKFLOW_PATH}" "${MACOS_WORKFLOW_PATH}" << 'PYTHON'
import sys
from pathlib import Path

required_paths = [
    "home/dot_mise/config.toml",
    "install/common/mise.sh",
    "home/.chezmoiscripts/common/run_once_after_02-install-mise.sh.tmpl",
    "home/.chezmoiscripts/common/run_after_20-install-mise-tools.sh.tmpl",
]

for workflow_path in map(Path, sys.argv[1:]):
    workflow = workflow_path.read_text(encoding="utf-8")
    for required_path in required_paths:
        path_entry = f'      - "{required_path}"'
        assert workflow.count(path_entry) == 2, (
            f"{workflow_path}: expected push and pull_request entries for "
            f"{required_path}"
        )
PYTHON

    [ "${status}" -eq 0 ]
}

@test "[common] repository guidance defines the mise compatibility contract" {
    run python3 - "${AGENTS_PATH}" << 'PYTHON'
import sys
from pathlib import Path

agents = Path(sys.argv[1]).read_text(encoding="utf-8")

assert "## mise Bootstrap Compatibility" in agents
assert "not as the desired installed version" in agents
assert "Raise `min_version` only in the same pull request" in agents
assert "must run both Ubuntu and macOS setup workflows" in agents
PYTHON

    [ "${status}" -eq 0 ]
}
