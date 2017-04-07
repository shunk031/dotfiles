# Paths

# for local bin
export PATH=${PATH}:~/.local/bin

# for Android SDK
export PATH=${PATH}:~/Android/Sdk/tools:~/Android/Sdk/platform-tools

# for my scripts
export PATH=${PATH}:~/dotfiles/script
export PATH=${PATH}:~/emacs.d/etc

# for CUDA PATH in Xiaomi Notebook Air
if [ -e /usr/local/cuda ]; then
   export PATH=/usr/local/cuda/bin:$PATH
   export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
fi
