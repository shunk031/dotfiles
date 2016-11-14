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

readonly FCITX_IMLIST_DIR=~/fcitx-imlist

nowinstall "Disable switch-group keybindings"
gsettings set org.gnome.desktop.wm.keybindings switch-group '[]'
gsettings set org.cinnamon.muffin.keybindings switch-group '[]'
gsettings set org.cinnamon.desktop.keybindings.wm switch-group '[]'
echo "Disabled switch-group keybindings."

nowinstall "Install fcitx-imlist"
if [ -e $FCITX_IMLIST_DIR ]; then
    echo -e "\nFcitx-imlist is alreader installed.\n"
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


