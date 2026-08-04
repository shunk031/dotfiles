#!/usr/bin/env bats

readonly SKILL_ROOT="./home/dot_config/exact_agents/skills"
readonly SYMLINK_ROOTS="./home/exact_dot_agents/skills ./home/dot_gemini/config/skills"

@test "[common] every managed skill has matching symlink templates" {
    local symlink_root
    local skill_name
    local template_file
    local expected_target

    while IFS= read -r -d '' skill_file; do
        skill_name="$(basename -- "$(dirname -- "${skill_file}")")"
        expected_target="{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/${skill_name}"

        for symlink_root in ${SYMLINK_ROOTS}; do
            template_file="${symlink_root}/symlink_${skill_name}.tmpl"
            [ -f "${template_file}" ]
            [ "$(< "${template_file}")" = "${expected_target}" ]
        done
    done < <(find "${SKILL_ROOT}" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | sort -z)
}
