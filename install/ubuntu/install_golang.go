package ubuntu

import (
	"shunk031/dotfiles/install/util"
)

func (g Golang) installGolang() {

	apt := AptCmd{}
	if !packageIsInstalled("golang") {

		apt.Install("software-properties-common", "software-properties-common")

		apt.AddPpa("longsleep/golang-backports")
		apt.Update()
	}

	apt.Install("golang", "golang")

}

type Golang struct {
	util.Helper
}

func (g Golang) Install() {
	g.Print()
	g.installGolang()
}

func NewGolang() SetupUbuntu {
	helper := util.Helper{"golang"}
	return Golang{helper}
}
