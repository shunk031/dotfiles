#!/usr/bin/env bash

# @file install/common/rtk.sh
# @brief Initialize RTK integrations for the configured agent CLIs.
# @description
#   Activates mise and lets the pinned RTK binary generate its agent-specific
#   files. Codex uses the managed `AGENTS.md` guidance instead of a generated
#   `@RTK.md` reference or a programmatic hook.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

#
# @description Activate `mise` so the configured RTK binary is on `PATH`.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Generate the supported global RTK integrations with telemetry disabled.
# @see https://www.rtk-ai.app/docs/getting-started/quick-start/
#
function initialize_rtk() {
    RTK_TELEMETRY_DISABLED=1 rtk init -g --auto-patch
    RTK_TELEMETRY_DISABLED=1 rtk init -g --gemini --auto-patch
}

#
# @description Run the RTK setup workflow after mise-managed tools are ready.
#
function main() {
    activate_mise
    command -v rtk > /dev/null
    initialize_rtk
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
