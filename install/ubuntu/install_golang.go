package ubuntu

import (
	"shunk031/dotfiles/install/util"
)

func installGolang() {

	apt := AptCmd{}
	if !packageIsInstalled("golang") {

		apt.Install("software-properties-common", "software-properties-common")

		apt.AddPpa("longsleep/golang-backports")
		apt.Update()
	}

	apt.Install("golang", "golang")

}

func InstallGolang() {
	util.PrintInPurple("Golang")
	installGolang()
}
