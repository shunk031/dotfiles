#!/bin/sh

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
readonly PREZTO_DIR=~/.prezto
readonly RICTY_FILE=~/.fonts/Ricty*.ttf
readonly DEVILSPIE_DIR=~/.devilspie


echo "$setupsh_logo"


# Download my dotfiles from github
if [ -e $DOTFILES_DIR ]; then
    echo -n "\ndotfiles is already cloned.\n"
else
    git clone https://github.com/shunk031/dotfiles.git ~/dotfiles
fi



# Create some dotfile symbolic links to home directory
ln -sfn ~/dotfiles/bashrc ~/.bashrc
echo "Created symbolic link of bashrc to home directory"

ln -sfn ~/dotfiles/profile ~/.profile
echo "Created symbolic link of profile to home directory"

ln -sfn ~/dotfiles/Xresources ~/.Xresources
echo "Created symbolic link of Xresources to home directory"

ln -sfn ~/dotfiles/xinitrc ~/.xinitrc
echo "Created symbolic link of xinitrc to home directory"

ln -sfn ~/dotfiles/xsession ~/.xsession
echo "Created symbolic link of xsession to home directory"

ln -sfn ~/dotfiles/zshrc ~/.zshrc
echo "Created symbolic link of zshrc to home directory"

ln -sfn ~/dotfiles/zlogin ~/.zlogin
echo "Created symbolic link of zlogin to home directory"

ln -sfn ~/dotfiles/zlogout ~/.zlogout
echo "Created symbolic link of zlogout to home directory"

ln -sfn ~/dotfiles/zpreztorc ~/.zpreztorc
echo "Created symbolic link of zpreztorc to home directory"

ln -sfn ~/dotfiles/zprofile ~/.zprofile
echo "Created symbolic link of zprofile to home directory"

ln -sfn ~/dotfiles/zshenv ~/.zshenv
echo "Created symbolic link of zshenv to home directory"

ln -sfn ~/dotfiles/Xmodmap ~/.Xmodmap
echo "Created symbolic link of Xmodmap to home directory"



# Create devilspie symbolic link to home directory
if [[ "$OSTYPE" =~ "linux-gnu" ]]; then
    mkdir -p $DEVILSPIE_DIR
    ln -sfn ~/dotfiles/devilspie/devilspie-script.ds ~/.devilspie/devilspie-script.ds
    echo "Created symbolic link of devilspie script to home directory"
fi



# Setup Prezto
if [ -e $PREZTO_DIR ]; then
    echo -n "\nPrezto is already installed.\n"
else
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    setopt EXTENDED_GLOB

    # Create some symblic link to ~/.prezto
    ln -sfn ~/dotfiles/prezto.d/prompt_sorin_setup ~/.zprezto/modules/prompt/functions/prompt_sorin_setup
    echo "Created symbolic link of prompt_sorin_setup to ~/.zprezto"

    ln -sfn ~/dotfiles/prezto.d/prompt_my_sorin_setup ~/.zprezto/modules/prompt/functions/prompt_my_sorin_setup
    echo "Created symbolic link of prompt_my_sorin_setup to ~/.zprezto"
fi



# called install.sh
sh $DOTFILES_DIR/install.sh



# Setup geeknote
which geeknote > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -n "\ngeeknote is already installed.\n"
else
    echo "Please input your evernote login ID(mail address)"
    geeknote login
    
    echo "Change default editor setting(Emacs)"
    geeknote settings --editor emacs
fi



# Install font "Ricty"
ls $RICTY_FILE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Now install Ricty"
    sh $DOTFILES_DIR/setup-ricty.sh
else
    echo -n "\nRicty is already installed.\n"
fi
