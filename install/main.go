package main

import (
	"fmt"
	"log"
	"os"
	"path"
)

const DotfilesLogo = `
                          /$$                                      /$$
                         | $$                                     | $$
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$
                                           | $$
                                           |__/
                     *** This is dotfiles setup script ***
                1. Download https://github.com/shunk031/dotfiles
                2. Symlink dotfiles to your home directory
`

const GitHubRepository = "shunk031/dotfiles"

var (
	DotfilesOrigin     = "git@github.com:" + GitHubRepository + ".git"
	DotfilesDirectory  = path.Join(os.Getenv("HOME"), ".dotfiles")
	DotfilesTarballUrl = path.Join("https://github.com", GitHubRepository, "tarball/master")
	IsSkipQuestions    = false
)

func verifyOS() error {
	const minimumMacosVersion = "10.10"
	const minimumUbuntuVersion = "18.04"

	osName := getOS()
	osVersion := getOSVersion()

	if osName == "macos" {
		if isSupportedVersion(osVersion, minimumMacosVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for macOS %s", minimumMacosVersion)
		}
	} else if osName == "ubuntu" {
		if isSupportedVersion(osVersion, minimumUbuntuVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for Ubuntu %s+", minimumUbuntuVersion)
		}
	} else {
		return fmt.Errorf("Sorry, this script is intended only for macOS and Ubuntu")
	}
}

func download(url string, output string) error {
	msg := fmt.Sprintf("Download from %s to %s", url, output)

	var err error
	if cmdExists("curl") {
		err = execute(msg, "curl", "-LsSo", output, url)
		//                            │││└─ write output to file
		//                            ││└─ show error messages
		//                            │└─ don't show the progress meter
		//                            └─ follow redirects
	} else if cmdExists("wget") {
		err = execute(msg, "wget", "-qO", output, url)
		//                            │└─ write output to file
		//                            └─ don't show output
	}
	return err
}

func main() {
	fmt.Println(DotfilesLogo)

	err := verifyOS()
	if err != nil {
		log.Fatal(err)
	}

	downloadDotfiles()
}
