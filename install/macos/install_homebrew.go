package macos

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func getHomebrewGitConfigFilePath() (string, error) {
	cmd := exec.Command("brew", "--repository")
	output, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}

	confpath := filepath.Join(string(output), ".git", "config")
	if _, err := os.Stat(confpath); os.IsExist(err) {
		return confpath, nil
	} else {
		return "", fmt.Errorf("Homebrew (get config file path)")
	}

}

func installHomebrew() {

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

func isHomebrewAnalyticsDisabled(confpath string) bool {
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

func replaceHomebrewAnalyticsToDisabled(confpath string) {

	cmd := fmt.Sprintf("git config --file=%s --replace-all homebrew.analyticsdisabled true", confpath)
	err := exec.Command("/bin/bash", "-c", cmd).Run()
	if err != nil {
		log.Fatal(err)
	}
}

func optOutOfAnalytics() {

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Try to get the path of the `Homebrew` git config file.

	confpath, err := getHomebrewGitConfigFilePath()
	if err != nil {
		log.Fatal(err)
	}

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Opt-out of Homebrew's analytics.
	// https://github.com/Homebrew/brew/blob/0c95c60511cc4d85d28f66b58d51d85f8186d941/share/doc/homebrew/Analytics.md#opting-out

	if !isHomebrewAnalyticsDisabled(confpath) {
		replaceHomebrewAnalyticsToDisabled(confpath)
	}

	util.PrintResult("Homebrew (out-out of analytics)", err)
}

func InstallHomebrew() {
	util.PrintInPurple("Homebrew")

	installHomebrew()
	optOutOfAnalytics()

	brew := HomebrewCmd{}
	brew.Update()
	brew.Upgrade()
}
