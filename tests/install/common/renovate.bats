#!/usr/bin/env bats

readonly RENOVATE_CONFIG_PATH="./.github/renovate.json"
readonly MISE_CONFIG_PATH="./home/dot_mise/config.toml"

@test "[common] Renovate groups agent tooling independently of mise backends" {
    run python3 - "${RENOVATE_CONFIG_PATH}" "${MISE_CONFIG_PATH}" << 'PYTHON'
import json
import re
import sys
from pathlib import Path

renovate_path, mise_path = map(Path, sys.argv[1:])
renovate = json.loads(renovate_path.read_text(encoding="utf-8"))
mise_text = mise_path.read_text(encoding="utf-8")
renovate_text = json.dumps(renovate)

logical_names = {"claude-code", "codex", "herdr"}
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

assert {name.split("/")[-1] for name in configured_dep_names} == logical_names
assert configured_agents["claude-code"].startswith("aqua:")
assert configured_agents["codex"].startswith("aqua:")
assert agent_rule["matchManagers"] == ["mise"]
assert agent_rule["minimumReleaseAge"] == "0 days"
assert mise_rule_index < agent_rule_index

patterns = agent_rule["matchDepNames"]
assert patterns and all(pattern.startswith("/") and pattern.endswith("/") for pattern in patterns)
assert all(
    any(re.search(pattern[1:-1], dep_name) for pattern in patterns)
    for dep_name in configured_dep_names
)
assert not any(
    backend in pattern
    for pattern in patterns
    for backend in ("aqua:", "npm:", "github:", "ubi:")
)
assert "matchPackageNames" not in agent_rule
assert "npm:@anthropic-ai/claude-code" not in renovate_text
assert "npm:@openai/codex" not in renovate_text
PYTHON

    [ "${status}" -eq 0 ]
}
