package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installPowerline() {

	fontDir := filepath.Join(os.Getenv("DOTPATH"), ".github/powerline_fonts")
	fontURL := "https://github.com/powerline/fonts.git"

	msg := fmt.Sprintf("Clone to %s", fontDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fontDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", fontURL, fontDir)

	err := util.Execute(msg, "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Println(err)
	}

	err = util.Execute("Install", filepath.Join(fontDir, "install.sh"))
	if err != nil {
		log.Fatal(err)
	}
}

func installAwesomePowerline() {
	fontDir := filepath.Join(os.Getenv("DOTPATH"), ".github", "awesome_powerline_fonts")
	fontURL := "https://github.com/gabrielelana/awesome-terminal-fonts"

	msg := fmt.Sprintf("Clone to %s", fontDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fontDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", fontURL, fontDir)

	err := util.Execute(msg, "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Println(err)
	}

	cmdCd := fmt.Sprintf("cd %s", fontDir)
	cmdBuild := "./build.sh"
	err = util.Execute("Build", "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdCd, cmdBuild))
	if err != nil {
		log.Fatal(err)
	}

	cmdInstall := "./install.sh"
	err = util.Execute("Install", "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdCd, cmdInstall))
	if err != nil {
		log.Fatal(err)
	}
}

func InstallPowerlineFont() {
	util.PrintInPurple("   For powerline font")

	installPowerline()
	installAwesomePowerline()
}
