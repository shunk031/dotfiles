#!/usr/bin/env bash

export PS1='[\h: \w]\n\$ '

export PYENV_VIRTUALENV_DISABLE_PROMPT=1

function pyenv_virtualenv_update_prompt() {
    RED='\[\e[0;31m\]'
    GREEN='\[\e[0;32m\]'
    BLUE='\[\e[0;34m\]'
    RESET='\[\e[0m\]'

    if [ -z "$PYENV_VIRTUALENV_ORIGINAL_PS1" ]; then
        export PYENV_VIRTUALENV_ORIGINAL_PS1="$PS1"
    fi

    if [ -z "$PYENV_VIRTUALENV_GLOBAL_NAME" ]; then
        PYENV_VIRTUALENV_GLOBAL_NAME="$(pyenv global)"
        export PYENV_VIRTUALENV_GLOBAL_NAME
    fi

    VENV_NAME="$(pyenv version-name)"
    VENV_NAME="${VENV_NAME##*/}"
    GLOBAL_NAME="$PYENV_VIRTUALENV_GLOBAL_NAME"

    # non-global versions:
    COLOR="$BLUE"
    # global version:
    [ "$VENV_NAME" == "$GLOBAL_NAME" ] && COLOR="$RED"
    # virtual envs:
    [ "${VIRTUAL_ENV##*/}" == "$VENV_NAME" ] && COLOR="$GREEN"

    if [ -z "$COLOR" ]; then
        PS1="$PYENV_VIRTUALENV_ORIGINAL_PS1"
    else
        PS1="($COLOR${VENV_NAME}$RESET) $PYENV_VIRTUALENV_ORIGINAL_PS1"
    fi
    export PS1
}

export PROMPT_COMMAND="$PROMPT_COMMAND pyenv_virtualenv_update_prompt;"
