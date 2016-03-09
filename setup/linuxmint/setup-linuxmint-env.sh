#!/bin/sh

echo '

    /$$                       /$$               /$$ /$$               /$$      
   |__/                      | $$              | $$| $$              | $$      
    /$$ /$$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$ | $$| $$      /$$$$$$$| $$$$$$$ 
   | $$| $$__  $$ /$$_____/|_  $$_/   |____  $$| $$| $$     /$$_____/| $$__  $$
   | $$| $$  \ $$|  $$$$$$   | $$      /$$$$$$$| $$| $$    |  $$$$$$ | $$  \ $$
   | $$| $$  | $$ \____  $$  | $$ /$$ /$$__  $$| $$| $$     \____  $$| $$  | $$
   | $$| $$  | $$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$| $$ /$$ /$$$$$$$/| $$  | $$
   |__/|__/  |__/|_______/    \___/   \_______/|__/|__/|__/|_______/ |__/  |__/

   *** This is application install script ***
   Install the required application
'

echo '
======================================================================

	     Fix Failed To Fetch Google Chrome Repository

======================================================================
'
sudo sed -i -e 's/deb http/deb [arch=amd64] http/' "/etc/apt/sources.list.d/google-chrome.list"
sudo sed -i -e 's/deb http/deb [arch=amd64] http/' "/opt/google/chrome/cron/google-chrome"

sudo apt-get update
sudo apt-get -y upgrade

echo '
======================================================================

		  Install Japanese Input Environment

======================================================================
'
sudo apt-get install -y fcitx fcitx-mozc fcitx-libs-qt fcitx-libs-qt5 fcitx-frontend-qt5 fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-config-gtk fcitx-tools fcitx-ui-classic mozc-utils-gui

echo '
======================================================================

		    Change English name directory

======================================================================
'
env LANGUAGE=C LC_MESSAGES=C xdg-user-dirs-gtk-update

echo '
======================================================================

			Install guake terminal

======================================================================
'
sudo apt-get install -y guake

echo '
======================================================================

			   Install gparted

======================================================================
'
sudo apt-get install -y gparted

echo '
======================================================================

		       Install grub-customizer

======================================================================
'
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
sudo apt-get update && sudo apt-get install -y grub-customizer

echo '
======================================================================

			  Install Emacs 24.5

======================================================================
'
sudo apt-get install -y build-essential
sudo apt-get install -y libgtk2.0-dev libtiff4-dev libgif-dev libjpeg-dev libpng12-dev libxpm-dev libncurses-dev libxml2-dev
wget http://ftp.gnu.org/gnu/emacs/emacs-24.5.tar.gz
tar -xzvf emacs-24.5.tar.gz
rm emacs-24.5.tar.gz
cd emacs-24.5
./configure
make
sudo make install

echo '
======================================================================

			  Install cairo-dock

======================================================================
'
sudo apt-add-repository -y ppa:cairo-dock-team/ppa
sudo apt-get update && sudo apt-get install -y cairo-dock cairo-dock-plug-ins

echo '
======================================================================

			     Install git

======================================================================
'
sudo apt-get install python-software-properties
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update && sudo apt-get install -y git

git config --global user.name "Shunsuke KITADA"
git config --global user.email "septemtrio.ager@gmail.com"

git config --global color.ui auto

echo '
======================================================================

		       Install dconf-editor

======================================================================
'
sudo apt-get install -y dconf-editor
gsettings set org.cinnamon.desktop.interface gtk-key-theme "Emacs"

echo '
======================================================================

			  Install easystroke

======================================================================
'
sudo apt-get install -y easystroke
