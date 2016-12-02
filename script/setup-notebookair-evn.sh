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
   
   *** This is Xiaomi Notevook Air env setup script ***
'
echo "$setupsh_logo"

nowinstall () {
    n=70
    jot -b = -s "" ${n}
    printf "\n%*s\n\n" $(((${#1}+${n})/2)) "$1"
    jot -b = -s "" ${n}

}

nowsetup () {
    description='*** You will install the following applications ***'
    n=70
    jot -b = -s "" ${n}
    printf "\n%*s\n\n" $(((${#1}+${n})/2)) "$1"
    printf "\n%*s\n\n" $(((${#description}+${n})/2)) "$description"
    for i in `seq 1 ${#}`
    do
	if [ $i -gt 1 ]; then
	    printf "   * %s\n" "${1}"
	    shift
	else
	    shift
	fi
    done
    echo ""
    jot -b = -s "" ${n}
}

readonly DOTFILES_DIR=~/dotfiles
readonly FCITX_IMLIST_DIR=$DOTFILES_DIR/script/fcitx-imlist
readonly XSWIPE_DIR=$$DOTFILES_DIR/script/xSwipe
readonly XSERVER_XORG_INPUT_SYNAPTICS_DIR=$DOTFILES_DIR/script/xserver-xorg-input-synaptics


nowinstall "Disable switch-group keybindings"
gsettings set org.gnome.desktop.wm.keybindings switch-group '[]'
gsettings set org.cinnamon.muffin.keybindings switch-group '[]'
gsettings set org.cinnamon.desktop.keybindings.wm switch-group '[]'
echo "Disabled switch-group keybindings."

nowinstall "Install fcitx-imlist"
if [ -e $FCITX_IMLIST_DIR ]; then
    echo -e "\nFcitx-imlist is already installed.\n"
else
    
    sudo apt-get install build-essential fcitx-libs-dev
    git clone https://github.com/kenhys/fcitx-imlist
    cd fcitx-imlist
    ./autogen.sh
    ./configure
    make
    sudo make install
    
    gsettings set org.xdump.fcitximlist fcitx-imlist-default 'jp,mozc'
    gsettings set org.xdump.fcitximlist fcitx-imlist-alternative 'us,mozc'
fi


nowinstall "Setup Macbook like gestures"
# clone xSwipe repository and install libx11-guitest-perl
if [ -e $XSWIPE_DIR ]; then
    echo -e "\nxSwipe is already installed.\n"
else
    git clone https://github.com/iberianpig/xSwipe.git
    sudo apt-get install libx11-guitest-perl
fi
# clone xserver-xorg-input-synpatics and install the app
if [ -e $XSERVER_XORG_INPUT_SYNAPTICS_DIR ]; then
    echo -e "\nxserver-xorg-input-synaptics is already installed.\n"
else
    sudo apt-get install -y git build-essential libevdev-dev autoconf automake libmtdev-dev xorg-dev xutils-dev libtool
    sudo apt-get remove -y xserver-xorg-input-synaptics
    git clone https://github.com/Chosko/xserver-xorg-input-synaptics.git
    cd xserver-xorg-input-synaptics
    ./autogen.sh
    ./configure --exec_prefix=/usr
    make
    sudo make install
fi
