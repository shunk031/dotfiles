#!/usr/bin/env zsh

# @file home/dot_config/exact_shell/mise.zsh
# @brief Expose mise shims for minimal Zsh startup contexts.
# @description
#   Makes the standalone mise binary and mise shims available in non-interactive
#   Zsh sessions without loading interactive plugins or prompt configuration.

_mise_local_bin="${HOME%/}/.local/bin"
_mise_bin="${_mise_local_bin}/mise"
_mise_shims="${HOME%/}/.local/share/mise/shims"

if [ -x "${_mise_bin}" ]; then
    case ":${PATH}:" in
    *:"${_mise_local_bin}":*) ;;
    *) export PATH="${_mise_local_bin}:${PATH}" ;;
    esac

    if [ -d "${_mise_shims}" ]; then
        case ":${PATH}:" in
        *:"${_mise_shims}":*) ;;
        *) export PATH="${_mise_shims}:${PATH}" ;;
        esac
    fi
fi

unset _mise_bin _mise_local_bin _mise_shims
