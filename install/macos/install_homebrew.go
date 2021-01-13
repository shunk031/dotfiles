package macos

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"shunk031/dotfiles/install/util"
	"strings"
)

func (h Homebrew) getHomebrewGitConfigFilePath() (string, error) {
	cmd := exec.Command("brew", "--repository")
	output, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}

	brewRepoPath := strings.TrimSpace(string(output))
	confpath := filepath.Join(brewRepoPath, ".git", "config")

	if _, err := os.Stat(confpath); os.IsNotExist(err) {
		return "", fmt.Errorf("Homebrew (get config file path)")
	} else {
		return confpath, nil
	}
}

func (h Homebrew) installHomebrew() {

	var err error
	if !util.CmdExists("brew") {
		cmd := "printf \"\n\" | /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
		//        └─ simulate the ENTER keypress

		err = exec.Command("/bin/bash", "-c", cmd).Run()
		if err != nil {
			log.Println(err)
		}
	}

	util.PrintResult("Homebrew", err)
}

func (h Homebrew) isHomebrewAnalyticsDisabled(confpath string) bool {
	cmd := fmt.Sprintf("git config --file=%s --get homebrew.analyticsdisabled", confpath)
	output, err := exec.Command("/bin/bash", "-c", cmd).Output()
	if err != nil {
		log.Fatal(err)
	}

	isDisabled := string(output)
	if isDisabled == "true" {
		return true
	}
	return false
}

func (h Homebrew) replaceHomebrewAnalyticsToDisabled(confpath string) {

	cmd := fmt.Sprintf("git config --file=%s --replace-all homebrew.analyticsdisabled true", confpath)
	err := exec.Command("/bin/bash", "-c", cmd).Run()
	if err != nil {
		log.Fatal(err)
	}
}

func (h Homebrew) optOutOfAnalytics() {

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Try to get the path of the `Homebrew` git config file.

	confpath, err := h.getHomebrewGitConfigFilePath()
	if err != nil {
		log.Fatal(err)
	}

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Opt-out of Homebrew's analytics.
	// https://github.com/Homebrew/brew/blob/0c95c60511cc4d85d28f66b58d51d85f8186d941/share/doc/homebrew/Analytics.md#opting-out

	if !h.isHomebrewAnalyticsDisabled(confpath) {
		h.replaceHomebrewAnalyticsToDisabled(confpath)
	}

	util.PrintResult("Homebrew (out-out of analytics)", err)
}

type Homebrew struct {
	util.Helper
}

func (h Homebrew) Install() {
	h.Print()

	h.installHomebrew()
	h.optOutOfAnalytics()

	brew := HomebrewCmd{}
	brew.Update()
	brew.Upgrade()

}

func NewHomebrew() SetupMasOS {
	helper := util.Helper{"homebrew"}
	return Homebrew{helper}
}
