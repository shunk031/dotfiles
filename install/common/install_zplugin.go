package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (z Zplugin) installZplugin() {
	zpluginDir := filepath.Join(os.Getenv("HOME"), ".zplugin/bin")
	zpluginURL := "https://github.com/zdharma/zplugin.git"

	msg := fmt.Sprintf("Install to %s", zpluginDir)
	cmdRm := fmt.Sprintf("rm -rf %s", zpluginDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", zpluginURL, zpluginDir)

	err := util.Execute(msg, fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}
}

type Zplugin struct {
	util.Helper
}

func (z Zplugin) Install() {
	z.Print()

	z.installZplugin()
}

func NewZplugin() SetupCommon {
	helper := util.Helper{"zplugin"}
	return Zplugin{helper}
}
