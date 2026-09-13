#!/usr/bin/env zsh

# @file home/dot_config/exact_shell/mise.zsh
# @brief Expose mise shims and provide guarded Zsh activation.
# @description
#   Makes the standalone mise binary available to every Zsh process and
#   exposes mise shims to non-interactive Zsh, then provides system-specific
#   activation for interactive startup. The activation guard uses the hook
#   function or shim PATH as its source of truth so child Zsh processes do not
#   inherit a stale exported marker.

_mise_local_bin="${HOME%/}/.local/bin"
_mise_bin="${_mise_local_bin}/mise"
_mise_shims="${HOME%/}/.local/share/mise/shims"

if [[ -x "${_mise_bin}" ]]; then
    case ":${PATH}:" in
    *:"${_mise_local_bin}":*) ;;
    *) export PATH="${_mise_local_bin}:${PATH}" ;;
    esac

    if [[ ! -o interactive ]]; then
        case ":${PATH}:" in
        *:"${_mise_shims}":*) ;;
        *) export PATH="${_mise_shims}:${PATH}" ;;
        esac
    fi
fi

# @description Activate mise once for the requested system startup mode.
# @arg $1 mode `client` enables full hooks; `server` enables shims only.
# @exitcode 0 When mise is absent or the requested mode is already active.
# @exitcode 2 When mode is not `client` or `server`.
function mise_zsh_activate() {
    local mode="${1:-}"
    local mise_bin="${HOME%/}/.local/bin/mise"
    local mise_shims="${HOME%/}/.local/share/mise/shims"

    case "${mode}" in
    client | server) ;;
    # An unknown mode is a caller error, not a missing activation; fail loudly
    # so a typo cannot silently leave the requested startup mode inactive.
    *)
        return 2
        ;;
    esac

    if [[ ! -x "${mise_bin}" ]]; then
        return 0
    fi

    case "${mode}" in
    client)
        # Full activation registers _mise_hook plus precmd/chpwd hooks. Function
        # presence is this shell's source of truth: child shells re-activate,
        # while an exported marker would wrongly make them skip the hooks.
        if ((${+functions[_mise_hook]})); then
            return 0
        fi
        eval "$(${mise_bin} activate zsh)"
        ;;
    server)
        # Shims-only activation only exposes PATH, so inherited $path is the source
        # of truth and child shells must not prepend it again. The top-level helper
        # usually does this; this covers calls when .zshenv was not read.
        if ((${path[(Ie)${mise_shims}]})); then
            return 0
        fi
        eval "$(${mise_bin} activate zsh --shims)"
        ;;
    esac
}

unset _mise_bin _mise_local_bin _mise_shims
