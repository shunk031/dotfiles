#!/usr/bin/env bash

# @file install/common/codex-plugins.sh
# @brief Ensure Codex native plugins are installed and enabled.
# @description
#   Activates `mise`, inspects the installed plugins once, and installs only
#   missing or disabled plugins.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Activate `mise` so Codex resolves from the configured toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Install a Codex plugin when it is missing or disabled.
# @arg $1 installed_json JSON returned by `codex plugin list --json`.
# @arg $2 source GitHub repository used as the plugin marketplace source.
# @arg $3 plugin_id Plugin identifier in `plugin@marketplace` form.
#
function ensure_codex_plugin() {
    local installed_json="$1"
    local source="$2"
    local plugin_id="$3"

    if jq -e --arg plugin_id "${plugin_id}" 'any(.installed[]; .pluginId == $plugin_id and .enabled)' <<< "${installed_json}" > /dev/null; then
        return
    fi

    "${MISE_BIN}" exec -- codex plugin marketplace remove "${plugin_id#*@}" > /dev/null 2>&1 || true
    "${MISE_BIN}" exec -- codex plugin marketplace add \
        "${source}" \
        --ref main
    "${MISE_BIN}" exec -- codex plugin add \
        "${plugin_id}"
}

#
# @description Ensure all managed Codex native plugins are installed and enabled.
#
function install_codex_plugins() {
    local installed_json
    local codex_home="${CODEX_HOME:-${HOME}/.codex}"

    printf 'HOME=%s\nCODEX_HOME=%s\n' "${HOME}" "${CODEX_HOME:-<unset>}"
    printf '%s\n' "Entries in ${HOME}/.codex:"
    if [ -d "${HOME}/.codex" ]; then
        ls -la "${HOME}/.codex"
    else
        printf '%s\n' 'missing'
    fi
    if [ -e "${codex_home}/config.toml" ] || [ -L "${codex_home}/config.toml" ]; then
        printf 'config.toml present under Codex home: yes (%s)\n' "${codex_home}"
        if [ -L "${codex_home}/config.toml" ]; then
            local config_link_target
            local config_link_path
            config_link_target="$(readlink "${codex_home}/config.toml")"
            if [[ "${config_link_target}" = /* ]]; then
                config_link_path="${config_link_target}"
            else
                config_link_path="${codex_home}/${config_link_target}"
            fi
            local config_link_display="${config_link_target}"
            case "${config_link_path}" in
            "${HOME}/"*) config_link_display="~/${config_link_path#"${HOME}"/}" ;;
            esac
            printf 'config.toml symlink target: %s; target exists: %s\n' \
                "${config_link_display}" \
                "$(if [ -e "${config_link_path}" ]; then printf yes; else printf no; fi)"
        else
            printf '%s\n' 'config.toml symlink: no'
        fi
        "${MISE_BIN}" exec -- python3 - "${codex_home}/config.toml" << 'PY'
import os
import re
import sys
import tomllib
from pathlib import Path

config_path = Path(sys.argv[1])
try:
    with config_path.open("rb") as config_file:
        config = tomllib.load(config_file)
except Exception as error:
    print(f"config.toml path scan failed: {type(error).__name__}")
    raise SystemExit(0)

path_key = re.compile(r"(?:^|_)(?:path|file|dir|catalog|instructions|hooks?)(?:$|_)", re.I)
path_suffixes = (".toml", ".json", ".md", ".yaml", ".yml", ".txt", ".log")

def report_paths(value, parts=()):
    if isinstance(value, dict):
        for key, child in value.items():
            report_paths(child, (*parts, str(key)))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            report_paths(child, (*parts, str(index)))
    elif isinstance(value, str):
        key = ".".join(parts)
        if key == "profile":
            candidate = config_path.parent / f"{value}.config.toml"
            print(f"config path: profile -> {candidate}; exists={'yes' if candidate.exists() else 'no'}")
            return
        looks_like_path = (
            value.startswith(("/", "~/", "./", "../", "$"))
            or value.endswith(path_suffixes)
            or path_key.search(key)
        )
        if looks_like_path:
            expanded = os.path.expandvars(os.path.expanduser(value))
            candidate = Path(expanded)
            if not candidate.is_absolute():
                candidate = config_path.parent / candidate
            print(f"config path: {key} = {value!r}; exists={'yes' if candidate.exists() else 'no'}")

report_paths(config)
PY
    else
        printf 'config.toml present under Codex home: no (%s)\n' "${codex_home}"
    fi
    printf 'codex version: '
    "${MISE_BIN}" exec -- codex --version
    printf '%s\n' '--- RUST_LOG=debug codex plugin list ---'
    RUST_LOG=debug "${MISE_BIN}" exec -- codex plugin list || true

    installed_json="$("${MISE_BIN}" exec -- codex plugin list --json)"
    ensure_codex_plugin \
        "${installed_json}" \
        Imbad0202/academic-research-skills-codex \
        ars-codex@ars-codex
    ensure_codex_plugin \
        "${installed_json}" \
        DietrichGebert/ponytail \
        ponytail@ponytail
}

#
# @description Run the Codex native plugin installation workflow.
#
function main() {
    activate_mise
    install_codex_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
