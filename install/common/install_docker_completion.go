package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installDockerCompletion() {
	compDir := filepath.Join(os.Getenv("HOME"), ".zprezto", "modules", "completion", "external", "src")
	compURL := "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"
	outputDir := filepath.Join(compDir, "_docker")

	msg := fmt.Sprintf("Download to %s", compDir)
	err := util.Execute(msg, "curl", "-fLo", outputDir, compURL)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallDockerCompletion() {
	util.PrintInPurple("Completion for docker commands")
	installDockerCompletion()
}
