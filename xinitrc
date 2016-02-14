# Change keyboard repeat rate and delay
# Speed up cursor speed
xset r rate 200 25

# Change Keybindings
if [ -s ~/.Xmodmap ]; then
    xmodmap ~/.Xmodmap
fi
