package macos

import "shunk031/dotfiles/install/util"

func (e Emacs) installEmacs() {
	brew := HomebrewCmd{}
	brew.Tap("d12frosted/emacs-plus")
	brew.Install("emacs-plus@28 --with-spacemacs-icon", "emacs-plus ver. 28 with Spacemacs icon")
	brew.Link("emacs-plus")
}

type Emacs struct {
	util.Helper
}

func (e Emacs) Install() {
	e.Print()
	e.installEmacs()
}

func NewEmacs() SetupMasOS {
	helper := util.Helper{Name: "emacs"}
	return Emacs{helper}
}
