package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installGhq() {
	dir := filepath.Join(os.Getenv("HOME"), "ghq")

	msg := fmt.Sprintf("Install ghq")
	cmdGo := fmt.Sprintf("go get github.com/motemen/ghq")
	cmdMkdir := fmt.Sprintf("mkdir -p %s", dir)

	cmd := fmt.Sprintf("%s; %s", cmdGo, cmdMkdir)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallGhq() {
	util.PrintInPurple("ghq")
	installGolang()
	installGhq()
}
