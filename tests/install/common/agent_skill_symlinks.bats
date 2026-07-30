#!/usr/bin/env bats

readonly SKILL_ROOT="./home/dot_config/exact_agents/skills"
readonly SYMLINK_ROOT="./home/exact_dot_agents/skills"

@test "[common] every managed skill has a matching symlink template" {
    while IFS= read -r -d '' skill_file; do
        skill_name="$(basename -- "$(dirname -- "${skill_file}")")"
        template_file="${SYMLINK_ROOT}/symlink_${skill_name}.tmpl"
        expected_target="{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/${skill_name}"

        [ -f "${template_file}" ]
        [ "$(< "${template_file}")" = "${expected_target}" ]
    done < <(find "${SKILL_ROOT}" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | sort -z)
}
