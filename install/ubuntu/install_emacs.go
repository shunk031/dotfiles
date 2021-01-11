package ubuntu

import "shunk031/dotfiles/install/util"

func installEmacs() {
	apt := AptCmd{}
	apt.Install("emacs", "Emacs", "")
}

func InstallEmacs() {
	util.PrintInPurple("Emacs")
	installEmacs()
}
