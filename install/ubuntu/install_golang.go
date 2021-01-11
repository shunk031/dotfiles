package ubuntu

import "shunk031/dotfiles/install/util"

func installGolang() {
	if !packageIsInstalled("golang") {
		apt := AptCmd{}
		apt.Install("software-properties-common", "software-properties-common")
	}

}

func InstallGolang() {
	util.PrintInPurple("Golang")
	installGolang()
}
