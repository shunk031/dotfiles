#!/usr/bin/env zsh

#
# for pyenv
#
export PYENV_ROOT="${HOME}/.pyenv"

typeset -gU path
path=(
    $path
    ${PYENV_ROOT%/}/bin(N-/)
)

eval "$(pyenv init -)"

#
# for pyenv-virtualenv
#
# eval "$(pyenv virtualenv-init - | sed s/precmd/chpwd/g)"
eval "$(pyenv virtualenv-init -)"

export PYENV_VIRTUALENV_DISABLE_PROMPT=1
