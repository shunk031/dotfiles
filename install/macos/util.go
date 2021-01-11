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
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "tap", repo)
	if err != nil {
		log.Println(err)
	}
}

func (h HomebrewCmd) Link(link string) {
	msg := fmt.Sprintf("brew link to %s", link)
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "link", link)
	if err != nil {
		log.Println(err)
	}
}

func (h HomebrewCmd) Install(formula string, msg string) {
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "install", formula)
	if err != nil {
		log.Fatal(err)
	}
}

func (h HomebrewCmd) InstallWithCask(formula string, msg string) {
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "install", "--cask", formula)
	if err != nil {
		log.Fatal(err)
	}
}

func (h HomebrewCmd) Update() {
	msg := "Homebrew (update)"
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "upgrade")
	if err != nil {
		log.Println(err)
	}

}

func (h HomebrewCmd) Upgrade() {
	msg := "Homebrew (upgrade)"
	err := util.Execute(msg, "/bin/bash", "-c", "brew", "update")
	if err != nil {
		log.Println(err)
	}
}
