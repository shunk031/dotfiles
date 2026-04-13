#!/usr/bin/env bash

# @file scripts/generate-docs.sh
# @brief Generate the MkDocs input for shell-based repository assets.
# @description
#   Collects tracked shell sources, renders Markdown reference pages, creates a
#   curated landing page, and writes a chezmoi template mapping page under
#   `docs/`.

set -Eeuo pipefail

readonly DOCS_DIR="docs"
readonly REFERENCE_DIR="${DOCS_DIR}/reference"
readonly LANDING_PAGE="${DOCS_DIR}/index.md"
readonly CATALOG_PAGE="${DOCS_DIR}/catalog.md"
readonly TEMPLATE_MAPPING_PAGE="${REFERENCE_DIR}/chezmoi-templates.md"
readonly LANDING_PREVIEW_LIMIT=6

#
# @description Regenerate every public docs page under `docs/`.
#
function main() {
    clean_generated_docs
    generate_reference_pages
    generate_template_mapping_page
    generate_catalog_placeholder
    generate_landing_page
}

#
# @description Remove stale generated docs before a new generation pass.
#
function clean_generated_docs() {
    rm -rf "${REFERENCE_DIR}"
    rm -f "${LANDING_PAGE}" "${CATALOG_PAGE}"
    mkdir -p "${REFERENCE_DIR}"
}

#
# @description List tracked shell source files that should become public docs.
#
function collect_source_files() {
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git ls-files -- \
            ":(glob)install/**/*.sh" \
            ":(glob)scripts/**/*.sh" \
            ":(glob)home/dot_local/bin/**" \
            ":(glob)home/dot_claude/hooks/**" \
            ":(glob)home/dot_config/alias/*.sh"
        return
    fi

    if [[ -d "install" ]]; then
        find "install" -type f -name "*.sh"
    fi

    if [[ -d "scripts" ]]; then
        find "scripts" -type f -name "*.sh"
    fi

    if [[ -d "home/dot_local/bin" ]]; then
        find "home/dot_local/bin" -type f
    fi

    if [[ -d "home/dot_claude/hooks" ]]; then
        find "home/dot_claude/hooks" -type f
    fi

    if [[ -d "home/dot_config/alias" ]]; then
        find "home/dot_config/alias" -type f -name "*.sh"
    fi
}

#
# @description List tracked chezmoi wrapper templates for mapping generation.
#
function collect_template_files() {
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git ls-files -- ":(glob)home/.chezmoiscripts/**/*.tmpl" | LC_ALL=C sort
        return
    fi

    if [[ -d "home/.chezmoiscripts" ]]; then
        find "home/.chezmoiscripts" -type f -name "*.tmpl" | LC_ALL=C sort
    fi
}

#
# @description Convert a source file path into its generated Markdown path.
# @arg $1 path Source file path relative to the repository root.
#
function output_path_for_source() {
    local source_path="$1"
    local output_path="${REFERENCE_DIR}/${source_path}"

    if [[ "${output_path}" == *.sh ]]; then
        output_path="${output_path%.sh}.md"
    else
        output_path="${output_path}.md"
    fi

    printf "%s\n" "${output_path}"
}

#
# @description Classify a source file into a stable landing-page group.
# @arg $1 path Source file path relative to the repository root.
#
function source_group_for_path() {
    local source_path="$1"

    case "${source_path}" in
    install/*)
        printf "install\n"
        ;;
    scripts/*)
        printf "scripts\n"
        ;;
    home/dot_local/bin/*)
        printf "commands\n"
        ;;
    home/dot_claude/hooks/*)
        printf "hooks\n"
        ;;
    home/dot_config/alias/*)
        printf "aliases\n"
        ;;
    *)
        printf "other\n"
        ;;
    esac
}

#
# @description Classify a source file for generated page metadata.
# @arg $1 path Source file path relative to the repository root.
#
function source_category_for_path() {
    local group

    group="$(source_group_for_path "$1")"

    case "${group}" in
    install)
        printf "install script\n"
        ;;
    scripts)
        printf "repository script\n"
        ;;
    commands)
        printf "shell executable\n"
        ;;
    hooks)
        printf "Claude hook\n"
        ;;
    aliases)
        printf "shell aliases\n"
        ;;
    *)
        printf "shell source\n"
        ;;
    esac
}

#
# @description Return the human-readable title for a landing-page group.
# @arg $1 string Stable group slug.
#
function source_group_title() {
    local group="$1"

    case "${group}" in
    install)
        printf "Install Scripts\n"
        ;;
    scripts)
        printf "Repository Scripts\n"
        ;;
    commands)
        printf "Local Commands\n"
        ;;
    hooks)
        printf "Claude Hooks\n"
        ;;
    aliases)
        printf "Alias Bundles\n"
        ;;
    *)
        printf "Other Sources\n"
        ;;
    esac
}

#
# @description Return the summary sentence for a landing-page group.
# @arg $1 string Stable group slug.
#
function source_group_description() {
    local group="$1"

    case "${group}" in
    install)
        printf 'Bootstrap and application setup flows stored under `install/**`.\n'
        ;;
    scripts)
        printf 'Repository maintenance and verification helpers under `scripts/**`.\n'
        ;;
    commands)
        printf 'Executable helpers published from `home/dot_local/bin/**`.\n'
        ;;
    hooks)
        printf "Claude Code hook scripts that enforce local automation policies.\n"
        ;;
    aliases)
        printf "Shell alias collections for common, client, and server profiles.\n"
        ;;
    *)
        printf "Additional generated shell references.\n"
        ;;
    esac
}

#
# @description Extract the first meaningful leading comment from a source file.
# @arg $1 path Source file path relative to the repository root.
#
function extract_summary() {
    local source_path="$1"
    local base_name

    base_name="$(basename "${source_path}")"

    awk -v base_name="${base_name}" '
        NR == 1 && /^#!/ { next }
        /^[[:space:]]*$/ {
            if (capturing) {
                print summary
                printed = 1
                exit
            }
            next
        }
        /^[[:space:]]*#/ {
            line = $0
            sub(/^[[:space:]]*#[[:space:]]?/, "", line)
            gsub(/[[:space:]]+/, " ", line)
            sub(/^[[:space:]]+/, "", line)
            gsub(/[[:space:]]+$/, "", line)

            if (line == "" || line == base_name || line ~ /^[-_#=*[:space:]]+$/) {
                if (capturing) {
                    print summary
                    printed = 1
                    exit
                }
                next
            }

            if (line ~ /^@/) {
                if (capturing) {
                    print summary
                    printed = 1
                    exit
                }
                next
            }

            if (capturing) {
                summary = summary " " line
            } else {
                summary = line
                capturing = 1
            }
            next
        }
        {
            if (capturing) {
                print summary
                printed = 1
            }
            exit
        }
        END {
            if (capturing && !printed) {
                print summary
            }
        }
    ' "${source_path}"
}

#
# @description Extract a short single-line summary suitable for landing-page cards.
# @arg $1 path Source file path relative to the repository root.
# @arg $2 int Maximum character count before truncation.
#
function short_summary_for_source() {
    local source_path="$1"
    local max_length="$2"
    local summary

    summary="$(extract_summary "${source_path}")"

    if [[ -z "${summary}" ]]; then
        printf "\n"
        return
    fi

    if [[ "${#summary}" -le "${max_length}" ]]; then
        printf "%s\n" "${summary}"
        return
    fi

    printf "%s...\n" "${summary:0:$((max_length - 3))}"
}

#
# @description Extract documented function names from a shell source file.
# @arg $1 path Source file path relative to the repository root.
#
function extract_function_names() {
    local source_path="$1"

    awk '
        /^[[:space:]]*function[[:space:]]+[[:alpha:]_][[:alnum:]_]*[[:space:]]*\(\)[[:space:]]*\{/ {
            name = $0
            sub(/^[[:space:]]*function[[:space:]]+/, "", name)
            sub(/[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*$/, "", name)
            print name
            next
        }
        /^[[:space:]]*[[:alpha:]_][[:alnum:]_]*[[:space:]]*\(\)[[:space:]]*\{/ {
            name = $0
            sub(/^[[:space:]]*/, "", name)
            sub(/[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*$/, "", name)
            print name
        }
    ' "${source_path}" | LC_ALL=C sort -u
}

#
# @description Print the standard page header used by generated docs pages.
# @arg $1 path Source file path.
# @arg $2 string Generated category label.
# @arg $3 string Renderer identifier.
#
function print_page_header() {
    local source_path="$1"
    local category="$2"
    local renderer="$3"
    local summary=""

    if [[ "${renderer}" != "shdoc" ]]; then
        summary="$(extract_summary "${source_path}")"
    fi

    printf "# %s\n\n" "${source_path}"

    if [[ -n "${summary}" ]]; then
        printf "%s\n\n" "${summary}"
    fi

    printf '## Metadata\n\n'
    printf -- '- Source: `%s`\n' "${source_path}"
    printf -- '- Category: %s\n' "${category}"
    printf -- '- Renderer: `%s`\n\n' "${renderer}"
}

#
# @description Embed the raw source file in a fenced bash code block.
# @arg $1 path Source file path.
#
function print_source_block() {
    local source_path="$1"

    printf '## Source\n\n'
    printf '```bash\n'
    cat "${source_path}"
    printf '\n```\n'
}

#
# @description Render a shell source page using `shdoc` or the fallback format.
# @arg $1 path Source file path.
# @arg $2 string Generated category label.
#
function render_shell_page() {
    local source_path="$1"
    local category="$2"
    local shdoc_output

    if shdoc_output="$(mise exec shdoc -- shdoc < "${source_path}" 2> /dev/null)" && [[ -n "${shdoc_output//[[:space:]]/}" ]]; then
        print_page_header "${source_path}" "${category}" "shdoc"
        printf '## Generated Reference\n\n'
        awk '
            NR == 1 && /^# / { next }
            in_index {
                if (/^## /) {
                    in_index = 0
                } else {
                    next
                }
            }
            /^## Index$/ {
                in_index = 1
                next
            }
            { print }
        ' <<< "${shdoc_output}"
        return
    fi

    print_page_header "${source_path}" "${category}" "shell-fallback"

    local function_count=0

    while IFS= read -r function_name; do
        [[ -n "${function_name}" ]] || continue

        if [[ "${function_count}" -eq 0 ]]; then
            printf '## Functions\n\n'
        fi

        printf -- '- `%s`\n' "${function_name}"
        function_count=$((function_count + 1))
    done < <(extract_function_names "${source_path}")

    if [[ "${function_count}" -gt 0 ]]; then
        printf "\n"
    fi

    print_source_block "${source_path}"
}

#
# @description Render an alias file as a list of aliases plus source code.
# @arg $1 path Source file path.
# @arg $2 string Generated category label.
#
function render_alias_page() {
    local source_path="$1"
    local category="$2"
    local found_aliases=false

    print_page_header "${source_path}" "${category}" "alias-fallback"
    printf '## Aliases\n\n'

    while IFS= read -r line; do
        [[ "${line}" == alias\ * ]] || continue

        local alias_definition="${line#alias }"
        local alias_name="${alias_definition%%=*}"
        local alias_value="${alias_definition#*=}"

        printf -- '- `%s`: `%s`\n' "${alias_name}" "${alias_value}"
        found_aliases=true
    done < "${source_path}"

    if [[ "${found_aliases}" == false ]]; then
        printf "No aliases were detected.\n"
    fi

    printf "\n"
    print_source_block "${source_path}"
}

#
# @description Generate Markdown reference pages for all collected source files.
#
function generate_reference_pages() {
    while IFS= read -r source_path; do
        [[ -n "${source_path}" ]] || continue

        local output_path
        local category

        output_path="$(output_path_for_source "${source_path}")"
        category="$(source_category_for_path "${source_path}")"

        mkdir -p "$(dirname "${output_path}")"

        if [[ "${source_path}" == home/dot_config/alias/* ]]; then
            render_alias_page "${source_path}" "${category}" > "${output_path}"
        else
            render_shell_page "${source_path}" "${category}" > "${output_path}"
        fi
    done < <(collect_source_files | LC_ALL=C sort)
}

#
# @description Resolve the included `install/...` source for a chezmoi wrapper.
# @arg $1 path Template file path.
#
function resolve_template_target() {
    local template_path="$1"

    sed -n 's@.*{{[[:space:]]*include[[:space:]]*"\.\./\(install/[^"]*\)"[[:space:]]*}}.*@\1@p' "${template_path}" | head -n 1
}

#
# @description Convert a source path into a docs-relative Markdown link target.
# @arg $1 path Source file path.
#
function link_for_source_page() {
    local source_path="$1"
    local output_path

    output_path="$(output_path_for_source "${source_path}")"
    printf "%s\n" "${output_path#${REFERENCE_DIR}/}"
}

#
# @description Convert a source path into a landing-page Markdown link target.
# @arg $1 path Source file path.
#
function docs_link_for_source_page() {
    printf "reference/%s\n" "$(link_for_source_page "$1")"
}

#
# @description Generate a page mapping chezmoi wrapper templates to install scripts.
#
function generate_template_mapping_page() {
    local found_template=false

    {
        printf '# home/.chezmoiscripts Template Mapping\n\n'
        printf 'This page maps `home/.chezmoiscripts/**/*.tmpl` wrappers to the source scripts they include.\n\n'
        printf '## Mappings\n\n'

        while IFS= read -r template_path; do
            [[ -n "${template_path}" ]] || continue

            local target_path
            local target_link

            target_path="$(resolve_template_target "${template_path}")"
            if [[ -z "${target_path}" ]]; then
                printf "Warning: skipping unmapped template %s\n" "${template_path}" >&2
                continue
            fi

            target_link="$(link_for_source_page "${target_path}")"
            printf -- '- `%s` -> [`%s`](%s)\n' "${template_path}" "${target_path}" "${target_link}"
            found_template=true
        done < <(collect_template_files)

        if [[ "${found_template}" == false ]]; then
            printf "No template wrappers were found.\n"
        fi
        printf "\n"
    } > "${TEMPLATE_MAPPING_PAGE}"
}

#
# @description Create a placeholder catalog page until `mkdocs-toc-md` rewrites it.
#
function generate_catalog_placeholder() {
    {
        printf '# Catalog\n\n'
        printf 'This page is regenerated automatically by `mkdocs-toc-md` during `make docs`, `make serve`, or `make deploy`.\n'
    } > "${CATALOG_PAGE}"
}

#
# @description Count non-empty input lines from stdin.
#
function count_lines() {
    awk '
        NF { count++ }
        END { print count + 0 }
    '
}

#
# @description Count all collected source files.
#
function count_source_files() {
    collect_source_files | count_lines
}

#
# @description Count source files that belong to a single landing-page group.
# @arg $1 string Stable group slug.
#
function count_sources_for_group() {
    local group="$1"
    local count=0

    while IFS= read -r source_path; do
        [[ -n "${source_path}" ]] || continue

        if [[ "$(source_group_for_path "${source_path}")" == "${group}" ]]; then
            count=$((count + 1))
        fi
    done < <(collect_source_files | LC_ALL=C sort)

    printf "%s\n" "${count}"
}

#
# @description Count template wrappers that resolve to a source script.
#
function count_mapped_templates() {
    local count=0

    while IFS= read -r template_path; do
        [[ -n "${template_path}" ]] || continue

        if [[ -n "$(resolve_template_target "${template_path}")" ]]; then
            count=$((count + 1))
        fi
    done < <(collect_template_files)

    printf "%s\n" "${count}"
}

#
# @description Print one stat card for the generated landing page.
# @arg $1 string Large numeric value.
# @arg $2 string Card label.
# @arg $3 string Supplemental detail line.
#
function print_landing_stat() {
    local value="$1"
    local label="$2"
    local note="$3"

    printf '<div class="landing-stat">\n'
    printf '  <span class="landing-stat__value">%s</span>\n' "${value}"
    printf '  <span class="landing-stat__label">%s</span>\n' "${label}"
    printf '  <span class="landing-stat__note">%s</span>\n' "${note}"
    printf '</div>\n'
}

#
# @description Print the quick-start card shown on the landing page.
#
function print_quickstart_card() {
    cat << 'EOF'
<div class="landing-card landing-card--command" markdown="1">

<p class="landing-kicker">Quick Start</p>

### Build, preview, deploy

Run the documentation pipeline from the repository root.

```console
make docs
make serve PORT=8001
make deploy
```

</div>
EOF
}

#
# @description Print the pipeline summary card shown on the landing page.
#
function print_pipeline_card() {
    cat << 'EOF'
<div class="landing-card" markdown="1">

<p class="landing-kicker">Pipeline</p>

### Generated end to end

The site is rebuilt from tracked shell sources every time.

- `mise exec shdoc -- shdoc` renders structured script references when annotations exist
- fallback pages still expose aliases, functions, and raw source when `shdoc` is not enough
- `mkdocs-toc-md` writes the full navigation tree to [catalog.md](catalog.md)
- `uv run --with` keeps the MkDocs toolchain ephemeral

</div>
EOF
}

#
# @description Print the catalog overview card shown on the landing page.
# @arg $1 string Total number of source reference pages.
# @arg $2 string Number of mapped template wrappers.
#
function print_catalog_card() {
    local source_count="$1"
    local template_count="$2"

    cat << EOF
<div class="landing-card" markdown="1">

<p class="landing-kicker">Coverage</p>

### Browse the full tree

The homepage stays curated, while the complete generated table of contents lives on its own page.

- [Open the full catalog](catalog.md)
- **${source_count}** source reference pages are generated from tracked shell assets
- **${template_count}** chezmoi wrappers are mapped back to their source scripts

</div>
EOF
}

#
# @description Print the template-mapping card shown on the landing page.
#
function print_template_mapping_card() {
    local mapped_count
    local shown_count=0

    mapped_count="$(count_mapped_templates)"

    printf '<div class="landing-card" markdown="1">\n\n'
    printf '<p class="landing-kicker">Chezmoi</p>\n\n'
    printf '### Template Mapping\n\n'
    printf 'Wrapper templates under `home/.chezmoiscripts` are linked back to the source scripts they include.\n\n'
    printf '_%s mapped wrappers_\n\n' "${mapped_count}"
    printf -- '- [Open template mapping](reference/chezmoi-templates.md)\n'

    while IFS= read -r template_path; do
        [[ -n "${template_path}" ]] || continue

        local target_path

        target_path="$(resolve_template_target "${template_path}")"
        [[ -n "${target_path}" ]] || continue

        if [[ "${shown_count}" -ge "${LANDING_PREVIEW_LIMIT}" ]]; then
            continue
        fi

        printf -- '- `%s` -> [`%s`](%s)\n' \
            "${template_path}" \
            "${target_path}" \
            "$(docs_link_for_source_page "${target_path}")"
        shown_count=$((shown_count + 1))
    done < <(collect_template_files)

    if [[ "${mapped_count}" -gt "${shown_count}" ]]; then
        printf '\n[%s more mappings](reference/chezmoi-templates.md)\n' "$((mapped_count - shown_count))"
    fi

    printf '\n</div>\n'
}

#
# @description Print one category card with a preview of generated pages.
# @arg $1 string Stable group slug.
# @arg $2 int Number of links to preview before deferring to the catalog.
#
function print_category_card() {
    local group="$1"
    local preview_limit="$2"
    local title
    local description
    local total_count
    local shown_count=0

    title="$(source_group_title "${group}")"
    description="$(source_group_description "${group}")"
    total_count="$(count_sources_for_group "${group}")"

    if [[ "${total_count}" -eq 0 ]]; then
        return
    fi

    printf '<div class="landing-card" markdown="1">\n\n'
    printf '<p class="landing-kicker">%s</p>\n\n' "${title}"
    printf '### %s\n\n' "${title}"
    printf '%s\n\n' "${description}"
    printf '_%s documented entries_\n\n' "${total_count}"

    while IFS= read -r source_path; do
        [[ -n "${source_path}" ]] || continue

        if [[ "$(source_group_for_path "${source_path}")" != "${group}" ]]; then
            continue
        fi

        if [[ "${shown_count}" -ge "${preview_limit}" ]]; then
            continue
        fi

        local summary

        summary="$(short_summary_for_source "${source_path}" 120)"

        if [[ -n "${summary}" ]]; then
            printf -- '- [`%s`](%s): %s\n' \
                "${source_path}" \
                "$(docs_link_for_source_page "${source_path}")" \
                "${summary}"
        else
            printf -- '- [`%s`](%s)\n' \
                "${source_path}" \
                "$(docs_link_for_source_page "${source_path}")"
        fi

        shown_count=$((shown_count + 1))
    done < <(collect_source_files | LC_ALL=C sort)

    if [[ "${total_count}" -gt "${shown_count}" ]]; then
        printf '\n[%s more entries in the full catalog](catalog.md)\n' "$((total_count - shown_count))"
    fi

    printf '\n</div>\n'
}

#
# @description Generate the rich top-level landing page under `docs/index.md`.
#
function generate_landing_page() {
    local source_count
    local install_count
    local script_count
    local command_count
    local hook_count
    local alias_count
    local template_count

    source_count="$(count_source_files)"
    install_count="$(count_sources_for_group "install")"
    script_count="$(count_sources_for_group "scripts")"
    command_count="$(count_sources_for_group "commands")"
    hook_count="$(count_sources_for_group "hooks")"
    alias_count="$(count_sources_for_group "aliases")"
    template_count="$(count_mapped_templates)"

    {
        printf '<div class="landing-hero" markdown="1">\n\n'
        printf '<p class="landing-hero__eyebrow">Generated with shdoc, MkDocs Material, toc-md, and uv</p>\n\n'
        printf '# Dotfiles Shell Automation Docs\n\n'
        printf 'Reference for installation flows, local commands, aliases, Claude hooks, and chezmoi wrappers maintained in this repository.\n\n'
        printf '<div class="landing-actions" markdown="1">\n\n'
        printf '[Browse Full Catalog](catalog.md){ .md-button .md-button--primary }\n'
        printf '[View Template Mapping](reference/chezmoi-templates.md){ .md-button }\n'
        printf '\n</div>\n\n'
        printf '</div>\n\n'

        printf '<div class="landing-stats">\n'
        print_landing_stat "${source_count}" "source docs" "tracked shell assets"
        print_landing_stat "${install_count}" "install scripts" "bootstrap and app setup"
        print_landing_stat "${script_count}" "repo scripts" "maintenance and checks"
        print_landing_stat "${command_count}" "local commands" "helpers under home/dot_local/bin"
        print_landing_stat "${hook_count}" "Claude hooks" "local automation policies"
        print_landing_stat "${alias_count}" "alias bundles" "common, client, server"
        print_landing_stat "${template_count}" "template mappings" "chezmoi wrappers"
        printf '</div>\n\n'

        printf '## Quick Start\n\n'
        printf '<div class="landing-grid landing-grid--summary">\n'
        print_quickstart_card
        print_pipeline_card
        print_catalog_card "${source_count}" "${template_count}"
        print_template_mapping_card
        printf '</div>\n\n'

        printf '## Browse By Area\n\n'
        printf 'Each section links to generated reference pages. Update source comments, then rerun `make docs` to refresh the site.\n\n'
        printf '<div class="landing-grid landing-grid--catalog">\n'
        print_category_card "install" "${LANDING_PREVIEW_LIMIT}"
        print_category_card "scripts" "${LANDING_PREVIEW_LIMIT}"
        print_category_card "commands" "${LANDING_PREVIEW_LIMIT}"
        print_category_card "hooks" "${LANDING_PREVIEW_LIMIT}"
        print_category_card "aliases" "${LANDING_PREVIEW_LIMIT}"
        printf '</div>\n'
    } > "${LANDING_PAGE}"
}

main "$@"
