package macos

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installGhq() {
	brew := HomebrewCmd{}
	brew.Install("ghq", "ghq")

	dir := filepath.Join(os.Getenv("HOME"), "ghq")

	msg := fmt.Sprintf("Make directory for ghq to %s", dir)
	cmd := fmt.Sprintf("mkdir -p %s", dir)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallGhq() {
	util.PrintInPurple("Install ghq")
	installGhq()

}
