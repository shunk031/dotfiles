package macos

import (
	"fmt"
	"log"
	"shunk031/dotfiles/install/util"
)

type HomebrewCmd struct {
}

func (h HomebrewCmd) Tap(repo string) {
	msg := fmt.Sprintf("brew tap to %s", repo)
	cmd := fmt.Sprintf("brew tap %s", repo)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Println(err)
	}
}

func (h HomebrewCmd) Link(link string) {
	msg := fmt.Sprintf("brew link to %s", link)
	cmd := fmt.Sprintf("brew link %s", link)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Println(err)
	}
}

func (h HomebrewCmd) Install(formula string, msg string) {
	cmd := fmt.Sprintf("brew install %s", formula)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func (h HomebrewCmd) InstallWithCask(formula string, msg string) {

	cmd := fmt.Sprintf("brew install --cask %s", formula)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func (h HomebrewCmd) Update() {
	msg := "Homebrew (update)"
	cmd := fmt.Sprintf("brew upgrade")
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Println(err)
	}

}

func (h HomebrewCmd) Upgrade() {
	msg := "Homebrew (upgrade)"
	cmd := fmt.Sprintf("brew update")
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Println(err)
	}
}
