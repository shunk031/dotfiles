#!/usr/bin/env zsh

# @file home/dot_config/exact_shell/mise.zsh
# @brief Activate mise shims for Zsh startup files.
# @description
#   Makes the standalone mise binary and mise shims available in Zsh startup
#   files without installing the full mise shell hooks or duplicating PATH
#   entries when this file is sourced more than once.

_mise_local_bin="${HOME%/}/.local/bin"
_mise_bin="${_mise_local_bin}/mise"
_mise_shims="${HOME%/}/.local/share/mise/shims"

if [ -x "${_mise_bin}" ]; then
    case ":${PATH}:" in
    *:"${_mise_local_bin}":*) ;;
    *) export PATH="${_mise_local_bin}:${PATH}" ;;
    esac

    case ":${PATH}:" in
    *:"${_mise_shims}":*) ;;
    *) eval "$("${_mise_bin}" activate zsh --shims)" ;;
    esac
fi

unset _mise_bin _mise_local_bin _mise_shims
