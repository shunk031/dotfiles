package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installZplugin() {
	zpluginDir := filepath.Join(os.Getenv("HOME"), ".zplugin/bin")
	zpluginURL := "https://github.com/zdharma/zplugin.git"

	msg := fmt.Sprintf("Install to %s", zpluginDir)
	cmdRm := fmt.Sprintf("rm -rf %s", zpluginDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", zpluginURL, zpluginDir)

	err := util.Execute(msg, "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}
}

func InstallZplugin() {
	util.PrintInPurple("For zplugin")
	installZplugin()
}
