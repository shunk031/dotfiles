package macos

import "shunk031/dotfiles/install/util"

func installEmacs() {
	brew := HomebrewCmd{}
	brew.Tap("d12frosted/emacs-plus")
	brew.Install("emacs-plus@28 --with-spacemacs-icon", "emacs-plus ver. 28 with Spacemacs icon")
	brew.Link("emacs-plus")
}

func InstallEmacs() {
	util.PrintInPurple("Emacs")
	installEmacs()
}
