#!/bin/sh

echo '
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
   3. To run install.sh in order to install the required application
'

# Create some symbolic link to home directory
ln -sfn ~/dotfiles/.bashrc ~/.bashrc
echo "Created symbolic link of .bashrc to home directory"

ln -sfn ~/dotfiles/.profile ~/.profile
echo "Created symbolic link of .profile to home directory"

ln -sfn ~/dotfiles/.Xresources ~/.Xresources
echo "Created symbolic link of .Xresources to home directory"

ln -sfn ~/dotfiles/.zshrc ~/.zshrc
echo "Created symbolic link of .zshrc to home directory"

ln -sfn ~/dotfiles/.zlogin ~/.zlogin
echo "Created symbolic link of .zlogin to home directory"

ln -sfn ~/dotfiles/.zlogout ~/.zlogout
echo "Created symbolic link of .zlogout to home directory"

ln -sfn ~/dotfiles/.zpreztorc ~/.zpreztorc
echo "Created symbolic link of .zpreztorc to home directory"

ln -sfn ~/dotfiles/.zprofile ~/.zprofile
echo "Created symbolic link of .zprofile to home directory"

ln -sfn ~/dotfiles/.zshenv ~/.zshenv
echo "Created symbolic link of .zshenv to home directory"



# called install.sh
sh install.sh



# install pyenv
git clone https://github.com/yyuu/pyenv.git ~/.pyenv



#install virtualenv
git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
