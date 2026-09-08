#!/usr/bin/env bash

# @file home/dot_config/exact_shell/mise.bash
# @brief Activate mise shims for Bash startup files.
# @description
#   Makes the standalone mise binary and mise shims available in interactive
#   non-login Bash sessions without duplicating PATH entries when this file is
#   sourced more than once.

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
    *) eval "$("${_mise_bin}" activate bash --shims)" ;;
    esac
fi

unset _mise_bin _mise_local_bin _mise_shims
