![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/header.png)

---

<p align="center">
  <a href="https://github.com/shunk031/dotfiles/actions?query=workflow%3A%22Snippet+install%22"><img src="https://github.com/shunk031/dotfiles/workflows/Snippet%20install/badge.svg" alt="Build Status"></a>
  <a href="http://spacemacs.org/"><img src="https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg" alt="spacemacs"></a>
  <a href="https://github.com/zsh-users/zsh"><img src="https://img.shields.io/badge/built%20with-zsh-black.svg" alt="zsh"></a>
  <a href="https://github.com/sorin-ionescu/prezto"><img src="https://img.shields.io/badge/built%20with-prezto-orange.svg" alt="prezto"></a>
  <a href="https://github.com/tmux/tmux"><img src="https://img.shields.io/badge/built%20with-tmux-green.svg" alt="tmux"></a>
</p>

---

# dotfiles

## Setup

To set up the dotfiles run the appropriate snippet in the terminal:

| OS     | Status | Snippet                                                |
|--------|--------|--------------------------------------------------------|
| MacOS  | [![Build Status](https://github.com/shunk031/dotfiles/workflows/MacOS/badge.svg)](https://github.com/shunk031/dotfiles/actions?query=workflow%3AMacOS) | `bash -c "$(curl -LsS http://shunk031.me/dotfiles/setup.sh)"`  |
| Ubuntu | [![Build Status](https://github.com/shunk031/dotfiles/workflows/Ubuntu/badge.svg)](https://github.com/shunk031/dotfiles/actions?query=workflow%3AUbuntu) | `bash -c "$(wget -qO - http://shunk031.me/dotfiles/setup.sh)"` |

## Packages

### For shell

| Package                                                      | Description                                                      |
|--------------------------------------------------------------|------------------------------------------------------------------|
| [zsh](https://github.com/zsh-users/zsh)                      | Mirror of the Z shell source code repository. http://www.zsh.org |
| [prezto](https://github.com/sorin-ionescu/prezto)            | The configuration framework for Zsh                              |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k)    | A fast reimplementation of Powerlevel9k ZSH theme                |
| [tmux](https://github.com/tmux/tmux)                         | tmux is a terminal multiplexer                                   |
| [tpm](https://github.com/tmux-plugins/tpm)                   | Tmux Plugin Manager                                              |
| [tmux-powerline](https://github.com/shunk031/tmux-powerline) | Statusbar for tmux that looks like vim-powerline forked from [erikw/tmux-powerline](https://github.com/erikw/tmux-powerline)
| [tmux-mem-cpu-load](https://github.com/thewtex/tmux-mem-cpu-load) | CPU, RAM, and load monitor for use with tmux |
| [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)        | Iconic font aggregator, collection, & patcher. 3,600+ icons, 40+ patched fonts |

### For command line

| Package                                | Description                            |
|----------------------------------------|----------------------------------------|
| [Spacemacs](https://github.com/syl20bnr/spacemacs) | A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim! |
| [ghq](https://github.com/motemen/ghq)  | Remote repository management made easy |
| [fzf](https://github.com/junegunn/fzf) | A command-line fuzzy finder            |
| [ag](https://github.com/ggreer/the_silver_searcher) | The Silver Searcher - a code-searching tool similar to ack, but faster. |
| [exa](https://github.com/ogham/exa) | A modern replacement for ‘ls’. |

### For MacOS Apps

#### Setting up iTerm2

- Open `iTerm2`.
- Select `iTerm2` > `Preferences`.

##### for General

1. Under the `General` tab in `Preferences`, check the box labeled `"Load preferences from a custom folder or URL:"`
2. Press `"Browse"` and point it to `~/.dotfiles/machines/macos/com.googlecode.iterm2.plist`

##### for Profiles
1. Under the `Profiles` tab, press `Other Actions...`.
2. Select `Import JSON profiles...`, then point it to `~/.dotfiles/machines/macos/hotkey_window.json`

- Then, restart iTerm2.

## Test with Docker

Build a test environment using docker to validate that it is set up correctly in the new environment.

```sh
$ cd .dotfiles
$ docker build -t dotfiles . --build-arg EXEC_USER=$(whoami)
$ docker run -it dotfiles /bin/bash
# or $ docker run -it -v $(pwd):/home/$(whoami)/.dotfiles dotfiles /bin/bash
$ bash setup.sh
```

## Acknowledgements

Inspiration and code was taken from many sources, including:

- [alrra/dotfiles](https://github.com/alrra/dotfiles): macOS / Ubuntu dotfiles from [@alrra](https://github.com/alrra).
- [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles): A repository that gathered files starting with dot from [@b4b4r07](https://github.com/b4b4r07).
- [da-edra/dotfiles](https://github.com/da-edra/dotfiles): Arch Linux config from [@da-edra](https://github.com/da-edra).

## License

The code is available under the [MIT license](https://github.com/shunk031/dotfiles/blob/master/LICENSE).
