package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

// func InstallPowerlineFont() {
// 	util.PrintInPurple("  For powerline font")

// 	installPowerline()
// 	installAwesomePowerline()
// }

type PowerlineFont struct {
	util.Helper
}

func (p PowerlineFont) Install() {
	p.Print()

	p.installPowerline()
	p.installAwesomePowerline()
}

func (p PowerlineFont) installPowerline() {

	fontDir := filepath.Join(os.Getenv("DOTPATH"), ".github/powerline_fonts")
	fontURL := "https://github.com/powerline/fonts.git"

	msg := fmt.Sprintf("Clone to %s", fontDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fontDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", fontURL, fontDir)

	err := util.Execute(msg, fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Println(err)
	}

	err = util.Execute("Install", filepath.Join(fontDir, "install.sh"))
	if err != nil {
		log.Fatal(err)
	}
}

func (p PowerlineFont) installAwesomePowerline() {
	fontDir := filepath.Join(os.Getenv("DOTPATH"), ".github", "awesome_powerline_fonts")
	fontURL := "https://github.com/gabrielelana/awesome-terminal-fonts"

	msg := fmt.Sprintf("Clone to %s", fontDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fontDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s --depth=1", fontURL, fontDir)
	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)

	err := util.Execute(msg, cmd)
	if err != nil {
		log.Println(err)
	}

	cmdCd := fmt.Sprintf("cd %s", fontDir)
	cmdBuild := "./build.sh"
	err = util.Execute("Build", fmt.Sprintf("%s; %s", cmdCd, cmdBuild))
	if err != nil {
		log.Fatal(err)
	}

	cmdInstall := "./install.sh"
	err = util.Execute("Install", fmt.Sprintf("%s; %s", cmdCd, cmdInstall))
	if err != nil {
		log.Fatal(err)
	}
}

func NewPowerlineFont() SetupCommon {
	helper := util.Helper{"powerline font"}
	return PowerlineFont{helper}
}
