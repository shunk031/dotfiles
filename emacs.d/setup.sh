#!/bin/bash

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

   *** This is My Emacs setup script ***

   1. Download https://github.com/shunk031/emacs.d.git
   2. Symlinking "emacs.d" to your home directory
   3. Setup GFM preview environment
   4. Setup Emacs realtime markdown viewer settings
   5. Setup Python development environment
   
'

readonly DOTEMACS=$HOME/.emacs.d
readonly MARKDOWN_SCRIPT=/bin/markdown

# Create some symbolic links to home directory
ln -sfn ~/emacs.d ~/.emacs.d
echo "Created symbolic link of .emacs.d to home directory"

ln -sfn ~/emacs.d/etc/aspell.conf ~/.aspell.conf
echo "Created symbolic link of .aspell.conf to home directory"



# Setup GFM preview environment
if [ -f $MARKDOWN_SCRIPT ]; then
    echo 'GFM preview environment has already created.'
else
    if [ "$(uname)" == 'Darwin' ]; then
	markdown_bin_path="/usr/local/bin/markdown"
    else
	markdown_bin_path="/bin/markdown"
    fi
    sudo ln -sfn ~/emacs.d/etc/markdown $markdown_bin_path && \
    echo "Created symbolic link of markdown to $markdown_bin_path"
    sudo chmod +x $markdown_bin_path && \
    sudo pip install grip && \
    echo "You can run GFM preview script!"
fi
