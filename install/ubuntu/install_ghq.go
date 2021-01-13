package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (g Ghq) installGhq() {
	dir := filepath.Join(os.Getenv("HOME"), "ghq")

	msg := fmt.Sprintf("Install ghq")
	cmdGo := fmt.Sprintf("go get github.com/motemen/ghq")
	cmdMkdir := fmt.Sprintf("mkdir -p %s", dir)

	cmd := fmt.Sprintf("%s; %s", cmdGo, cmdMkdir)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

type Ghq struct {
	util.Helper
}

func (g Ghq) Install() {
	g.Print()
	g.installGhq()
}

func NewGhq() SetupUbuntu {
	helper := util.Helper{Name: "ghq"}
	return Ghq{helper}
}
