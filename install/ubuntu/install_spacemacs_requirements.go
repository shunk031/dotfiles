package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (s SpacemacsRequirements) installSourceCodeProFont() {
	dir := filepath.Join(os.Getenv("HOME"), ".font", "adobe-fonts", "source-code-pro")
	URL := "https://github.com/adobe-fonts/source-code-pro.git"

	msg := fmt.Sprintf("Install font: Source Code Pro")
	cmdRm := fmt.Sprintf("rm -rf %s", dir)
	cmdGit := fmt.Sprintf("git clone --quiet --depth=1 --branch release %s %s", URL, dir)
	cmdFc := fmt.Sprintf("fc-cache -f %s", dir)

	cmd := fmt.Sprintf("%s; %s; %s", cmdRm, cmdGit, cmdFc)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}

}

type SpacemacsRequirements struct {
	util.Helper
}

func (s SpacemacsRequirements) Install() {
	s.Print()
	s.installSourceCodeProFont()
}

func NewSpacemacsRequirements() SetupUbuntu {
	helper := util.Helper{"spacemacs requirements"}
	return SpacemacsRequirements{helper}
}
