PYENV_DIR=${HOME}/.pyenv
PYENV_VIRTUALENV_DIR=${PYENV_DIR}/plugins/pyenv-virtualenv

if [ ! -e "$PYENV_DIR" ]; then
    e_header "Installing pyenv..."
    git clone -q https://github.com/yyuu/pyenv.git $PYENV_DIR
    e_newline && e_done "Install pyenv"
fi

if [ ! -e "$PYENV_VIRTUALENV_DIR" ]; then
    e_header "Installing pyenv-virtualenv..."
    git clone -q https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
    e_newline && e_done "Install pyenv-virtualenv"
fi

# Setup pyenv environment
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Setup pyenv-virtualenv enviroment
eval "$(pyenv virtualenv-init -)"

# disable virtualenv prompt
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
