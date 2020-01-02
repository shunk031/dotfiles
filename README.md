# dotfiles

![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/header.png)

---

<p align="center">
  <a href="https://github.com/shunk031/dotfiles/actions?query=workflow%3AUbuntu"><img src=https://github.com/shunk031/dotfiles/workflows/Ubuntu/badge.svg alt="Build Status"></a>
  <a href="https://github.com/shunk031/dotfiles/actions?query=workflow%3AMacOS"><img src=https://github.com/shunk031/dotfiles/workflows/MacOS/badge.svg alt="Build Status"></a>
  <a href="http://spacemacs.org/"><img src="https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg" alt="spacemacs"></a>
  <a href="https://github.com/zsh-users/zsh"><img src="https://img.shields.io/badge/built%20with-zsh-black.svg" alt="zsh"></a>
  <a href="https://github.com/sorin-ionescu/prezto"><img src="https://img.shields.io/badge/built%20with-prezto-orange.svg" alt="prezto"></a>
  <a href="https://github.com/tmux/tmux"><img src="https://img.shields.io/badge/built%20with-tmux-green.svg" alt="tmux"></a>
</p>

---

![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/mac.png)

## Setup

To set up the dotfiles run the appropriate snippet in the terminal:

| OS     | Snippet                                                        |
|--------|----------------------------------------------------------------|
| MacOS  | `bash -c "$(curl -LsS http://shunk031.me/dotfiles/setup.sh)"`  |
| Ubuntu | `bash -c "$(wget -qO - http://shunk031.me/dotfiles/setup.sh)"` |

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

## Test with Docker

Build a test environment using docker to validate that it is set up correctly in the new environment.

```shell
$ cd .dotfiles
$ docker build -t dotfiles .
$ docker run -it -v $(pwd):/root/dotfiles dotfiles /bin/bash
$ bash setup.sh
```

## License

The code is available under the [MIT license](https://github.com/shunk031/dotfiles/blob/master/LICENSE).
