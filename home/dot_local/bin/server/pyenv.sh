#!/usr/bin/env bash

#
# for pyenv
#
export PYENV_ROOT="${HOME}/.pyenv"
command -v pyenv >/dev/null || export PATH="$PATH:$PYENV_ROOT/bin"
eval "$(pyenv init -)"

#
# for pyenv-virtualenv
#
eval "$(pyenv virtualenv-init -)"
