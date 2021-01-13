package ubuntu

import "shunk031/dotfiles/install/util"

func (e Emacs) installEmacs() {
	apt := AptCmd{}
	apt.Install("emacs", "Emacs")
}

type Emacs struct {
	util.Helper
}

func (e Emacs) Install() {
	e.Print()
	e.installEmacs()
}

func NewEmacs() SetupUbuntu {
	helper := util.Helper{Name: "emacs"}
	return Emacs{helper}
}
