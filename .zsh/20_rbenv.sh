RBENV_DIR=${HOME}/.rbenv

if [ ! -e "$RBENV_DIR" ]; then
    e_header "Installing rbenv..."
    git clone https://github.com/rbenv/rbenv.git $RBENV_DIR
    ~/.rbenv/src/configure && make -C src
fi

if ! has 'ruby-build'; then
    e_header "Installing ruby-build..."
    mkdir -p "$(rbenv root)"/plugins
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
fi

# Setup rbenv environment
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
eval "$(rbenv init -)"
