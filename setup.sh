#!/bin/sh

# Create some symbolic link to home directory
ln -s ~/dotfiles/.bashrc ~/.bashrc
echo "Created symbolic link of .bashrc to ~/"

ln -s ~/dotfiles/.profile ~/.profile
echo "Created symbolic link of .profile to ~/"

ln -s ~/dotfiles/.Xresources ~/.Xresources
echo "Created symbolic link of .Xresources to ~/"

ln -s ~/dotfiles/.zshrc ~/.zshrc
echo "Created symbolic link of .zshrc to ~/"


# install pyenv
git clone https://github.com/yyuu/pyenv.git ~/.pyenv

#install virtualenv
git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
