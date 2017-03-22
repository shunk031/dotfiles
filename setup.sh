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
   4. To run install.sh in order to install the required application
   5. Setup geeknote -- evernote client
   6. Install Ricty -- fonts for programinng
'

readonly DOTFILES_DIR=~/dotfiles
readonly PREZTO_DIR=~/.zprezto
readonly DOTEMACS_DIR=~/emacs.d
readonly RICTY_FILE=(~/.fonts/Ricty*.ttf)
readonly DEVILSPIE_DIR=~/.devilspie



echo "$setupsh_logo"


# Download my dotfiles from github
if [ -e $DOTFILES_DIR ]; then
    echo -e "\n[ GIT CLONE ] dotfiles is already cloned.\n"
else
    git clone https://github.com/shunk031/dotfiles.git $DOTFILES_DIR
fi



# Create some dotfile symbolic links to home directory
ln -sfn $DOTFILES_DIR/bashrc ~/.bashrc
echo "[ SYMLINK ] Created symbolic link of bashrc to home directory"

ln -sfn $DOTFILES_DIR/profile ~/.profile
echo "[ SYMLINK ] Created symbolic link of profile to home directory"

ln -sfn $DOTFILES_DIR/Xresources ~/.Xresources
echo "[ SYMLINK ] Created symbolic link of Xresources to home directory"

ln -sfn $DOTFILES_DIR/xinitrc ~/.xinitrc
echo "[ SYMLINK ] Created symbolic link of xinitrc to home directory"

ln -sfn $DOTFILES_DIR/xsession ~/.xsession
echo "[ SYMLINK ] Created symbolic link of xsession to home directory"

ln -sfn $DOTFILES_DIR/zshrc ~/.zshrc
echo "[ SYMLINK ] Created symbolic link of zshrc to home directory"

ln -sfn $DOTFILES_DIR/zlogin ~/.zlogin
echo "[ SYMLINK ] Created symbolic link of zlogin to home directory"

ln -sfn $DOTFILES_DIR/zlogout ~/.zlogout
echo "[ SYMLINK ] Created symbolic link of zlogout to home directory"

ln -sfn $DOTFILES_DIR/zpreztorc ~/.zpreztorc
echo "[ SYMLINK ] Created symbolic link of zpreztorc to home directory"

ln -sfn $DOTFILES_DIR/zprofile ~/.zprofile
echo "[ SYMLINK ] Created symbolic link of zprofile to home directory"

ln -sfn $DOTFILES_DIR/zshenv ~/.zshenv
echo "[ SYMLINK ] Created symbolic link of zshenv to home directory"

ln -sfn $DOTFILES_DIR/Xmodmap ~/.Xmodmap
echo "[ SYMLINK ] Created symbolic link of Xmodmap to home directory"

ln -sfn $DOTFILES_DIR/tmux.conf ~/.tmux.conf
echo "[ SYMLINK ] Created symbolic link of tmux.conf to home directory"

ln -sfn $DOTFILES_DIR/gitconfig ~/.gitconfig
echo "[ SYMLINK ] Created symbolic link of gitconfig to home directory"

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
ln -sfn $DOTFILES_DIR/prezto.d/prompt_sorin_setup ~/.zprezto/modules/prompt/functions/prompt_sorin_setup
echo "[ SYMLINK ] Created symbolic link of prompt_sorin_setup to ~/.zprezto"

ln -sfn $DOTFILES_DIR/prezto.d/prompt_my_sorin_setup ~/.zprezto/modules/prompt/functions/prompt_my_sorin_setup
echo "[ SYMLINK ] Created symbolic link of prompt_my_sorin_setup to ~p/.zprezto"

ln -sfn $DOTFILES_DIR/prezto.d/prompt_my_powerline_setup ~/.zprezto/modules/prompt/functions/prompt_my_powerline_setup
echo "[ SYMLINK ] Created symbolic link of prompt_my_powerline_setup to ~/.zprezto"
    




# Clone my emacs.d
if [ -e $DOTEMACS_DIR ];then
    echo -e "[ INSTALL ] emacs.d is already cloned."
else
    git clone https://github.com/shunk031/emacs.d.git $DOTEMACS_DIR
    bash ~/emacs.d/setup.sh
fi



# Install font "Ricty"
ls $RICTY_FILE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[ INSTALL ] Now install Ricty..."
    bash $DOTFILES_DIR/script/setup-ricty.sh
else
    echo -e "[ INSTALL ] Ricty is already installed.\n"
fi
