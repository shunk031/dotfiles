package macos

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (g Ghq) installGhq() {
	brew := HomebrewCmd{}
	brew.Install("ghq", "ghq")

	dir := filepath.Join(os.Getenv("HOME"), "ghq")

	msg := fmt.Sprintf("Make directory for ghq to %s", dir)
	cmd := fmt.Sprintf("mkdir -p %s", dir)
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

func NewGhq() SetupMasOS {
	helper := util.Helper{Name: "ghq"}
	return Ghq{helper}
}
