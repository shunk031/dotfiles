package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (p Prezto) installPrezto() {
	zdotDir := os.Getenv("ZDOTDIR")
	if zdotDir == "" {
		zdotDir = os.Getenv("HOME")
	}
	preztoDir := filepath.Join(zdotDir, ".zprezto")
	preztoURL := "https://github.com/sorin-ionescu/prezto.git"

	msg := fmt.Sprintf("Install to %s", preztoDir)
	cmdRm := fmt.Sprintf("rm -rf %s", preztoDir)
	cmdGit := fmt.Sprintf("git clone --quiet --recursive %s %s", preztoURL, preztoDir)

	err := util.Execute(msg, fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}

}

type Prezto struct {
	util.Helper
}

func (p Prezto) Install() {
	p.Print()
	p.installPrezto()
}

func NewPrezto() SetupCommon {
	helper := util.Helper{"prezto"}
	return Prezto{helper}
}
