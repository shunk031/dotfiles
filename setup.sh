#!/bin/bash

setupsh_logo='
                          /$$                                      /$$      
                         | $$                                     | $$      
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$ 
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$                             
                                           | $$                             
                                           |__/
   
   *** This is dotfiles setup script ***
   1. Download https://github.com/shunk031/dotfiles
   2. Symlinking dot files to your home directory
   3. Setup Prezto
   4. Setup tpm | tmux plugin manager
'

readonly DOTFILES_DIR=~/dotfiles
readonly PREZTO_DIR=~/.zprezto

readonly TPM_DIR=~/.tmux/plugins/tpm
readonly POWERLINE_FONTS_DIR=~/dotfiles/powerline_fonts

readonly RICTY_FILE=(~/.fonts/Ricty*.ttf)
readonly DEVILSPIE_DIR=~/.devilspie

readonly PYENV_DIR=~/.pyenv
readonly PYENV_VIRTUALENV_DIR=~/.pyenv/plugins/pyenv-virtualenv
readonly PYENV_PIP_REFRESH_DIR=~/.pyenv/plugins/pyenv-pip-rehash

readonly RUBYENV_DIR=~/.rbenv
readonly RUBY_BUILD_DIR=~/.rbenv/plugins/ruby-build

readonly GOENV_DIR=~/.goenv



echo "$setupsh_logo"


# Download my dotfiles from github
if [ -e $DOTFILES_DIR ]; then
    echo -e "\n[ GIT CLONE ] dotfiles is already cloned.\n"
else
    git clone https://github.com/shunk031/dotfiles.git $DOTFILES_DIR
fi



# Create some dotfile symbolic links to home directory
ln -sfn $DOTFILES_DIR/prezto.d/zshrc.zsh ~/.zshrc
echo "[ SYMLINK ] Created symbolic link of zshrc to home directory"

ln -sfn $DOTFILES_DIR/prezto.d/zlogin.zsh ~/.zlogin
echo "[ SYMLINK ] Created symbolic link of zlogin to home directory"

ln -sfn $DOTFILES_DIR/prezto.d/zlogout.zsh ~/.zlogout
echo "[ SYMLINK ] Created symbolic link of zlogout to home directory"

ln -sfn $DOTFILES_DIR/prezto.d/zpreztorc.zsh ~/.zpreztorc
echo "[ SYMLINK ] Created symbolic link of zpreztorc to home directory"

ln -sfn $DOTFILES_DIR/prezto.d/zprofile.zsh ~/.zprofile
echo "[ SYMLINK ] Created symbolic link of zprofile to home directory"

ln -sfn $DOTFILES_DIR/prezto.d/zshenv.zsh ~/.zshenv
echo "[ SYMLINK ] Created symbolic link of zshenv to home directory"

ln -sfn $DOTFILES_DIR/tmux.d/tmux.conf ~/.tmux.conf
echo "[ SYMLINK ] Created symbolic link of tmux.conf to home directory"

ln -sfn $DOTFILES_DIR/tmux.d/tmux-powerlinerc.zsh ~/.tmux-powerlinerc
echo "[ SYMLINK ] Created symbolic link fo tmux-powerlinerc to home directory"

ln -sfn $DOTFILES_DIR/git_config/gitignore_global ~/.gitignore_global
echo "[ SYMLINK ] Created symbolic link of gitconfig to home directory"

ln -sfn $DOTFILES_DIR/emacs.d ~/.emacs.d
echo "[ SYMLINK ] Created symbolic link of emacs.d to home directory"

ln -sfn $DOTFILES_DIR/emacs.d/etc/aspell.conf ~/.aspell.conf
echo "[ SYMLINK ] Created symbolic link of aspell.conf to home directory"



# Setup Poweline fonts
if [ -e $POWERLINE_FONTS_DIR ]; then
    echo -e "[ INSTALL ] Powerline fonts is already installed."
else
    git clone https://github.com/powerline/fonts.git $POWERLINE_FONTS_DIR --depth=1
    cd $POWERLINE_FONTS_DIR
    ./install.sh
    cd ..
fi



# Create devilspie symbolic link to home directory
if [[ "$OSTYPE" =~ linux-gnu ]]; then
    if [ -e $DEVILSPIE_DIR ]; then
	echo -e "[ INSTALL ] devilspie is already installed."
    else
	mkdir -p $DEVILSPIE_DIR
	ln -sfn $DOTFILES_DIR/devilspie/devilspie-script.ds $DEVILSPIE_DIR/devilspie-script.ds
	echo "[ SYMLINK ] Created symbolic link of devilspie script to home directory"
    fi
fi



# Setup Prezto
if [ -e $PREZTO_DIR ]; then
    echo -e "[ INSTALL ] Prezto is already installed."
else
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    setopt EXTENDED_GLOB
fi

# Create some symblic link to ~/.prezto
ln -sfn $DOTFILES_DIR/prezto.d/prompt/prompt_my_powerline_setup.zsh ~/.zprezto/modules/prompt/functions/prompt_my_powerline_setup
echo "[ SYMLINK ] Created symbolic link of prompt_my_powerline_setup to ~/.zprezto"



# Clone tpm(tmux plugin manager)
if [ -e $TPM_DIR ]; then
    echo -e "[ INSTALL ] tpm is already cloned."
else
    git clone https://github.com/tmux-plugins/tpm $TPM_DIR

    git clone https://github.com/thewtex/tmux-mem-cpu-load.git
    cd tmux-mem-cpu-load
    cmake .
    make
    sudo make install
fi



# Clone "pyenv"
if [ -e $PYENV_DIR ]; then
    echo -e "\npyenv is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv.git $PYENV_DIR
fi

# Clone pyenv plugin "pyenv-virtualenv"
if [ -e $PYENV_VIRTUALENV_DIR ]; then
    echo -e "\npyenv-virtualenv is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
fi

# Clone pyenv plugin "pyenv-pip-refresh"
if [ -e $PYENV_PIP_REFRESH_DIR ]; then
    echo -e "\npyenv-pip-refresh is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv-pip-rehash.git $PYENV_PIP_REFRESH_DIR
fi



# Clone "rbenv"
if [ -e $RUBYENV_DIR ]; then
    echo -e "\nrbenv is already cloned.\n"
else
    git clone https://github.com/sstephenson/rbenv.git $RUBYENV_DIR
fi

# Clone "ruby-build"
if [ -e $RUBY_BUILD_DIR ]; then
    echo -e "\nruby-build is already cloned.\n"
else
    git clone https://github.com/sstephenson/ruby-build.git $RUBY_BUILD_DIR
fi


# Clone goenv
if [ -e $GOENV_DIR ]; then
    echo -e "\ngoenv is already cloned.\n"
else
    git clone https://github.com/syndbg/goenv.git $GOENV_DIR
fi
