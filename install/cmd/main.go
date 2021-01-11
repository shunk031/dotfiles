package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/common"
	"shunk031/dotfiles/install/macos"
	"shunk031/dotfiles/install/ubuntu"
	"shunk031/dotfiles/install/util"
)

const dotfilesLogo = `
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

const gitHubRepository = "shunk031/dotfiles"

func verifyOS() error {
	const minimumMacosVersion = "10.10"
	const minimumUbuntuVersion = "18.04"

	osName := util.GetOS()
	osVersion := util.GetOSVersion()

	if osName == "macos" {
		if util.IsSupportedVersion(osVersion, minimumMacosVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for macOS %s", minimumMacosVersion)
		}
	} else if osName == "ubuntu" {
		if util.IsSupportedVersion(osVersion, minimumUbuntuVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for Ubuntu %s+", minimumUbuntuVersion)
		}
	} else {
		return fmt.Errorf("Sorry, this script is intended only for macOS and Ubuntu")
	}
}

func main() {
	fmt.Println(dotfilesLogo)

	var (
		// DotfilesOrigin     = "git@github.com:" + gitHubRepository + ".git"
		DotfilesDirectory  = filepath.Join(os.Getenv("HOME"), ".dotfiles")
		DotfilesTarballURL = filepath.Join("https://github.com", gitHubRepository, "tarball/master")
		IsSkipQuestions    = false
	)

	err := verifyOS()
	if err != nil {
		log.Fatal(err)
	}

	util.DownloadDotfiles(
		DotfilesDirectory,
		DotfilesTarballURL,
		IsSkipQuestions,
	)

	util.PrintInPurple("\n• Installs\n")

	// OS common setup
	common.Setup()

	// OS specific setup
	osName := util.GetOS()
	if osName == "macos" {
		macos.Setup()
	} else if osName == "ubuntu" {
		ubuntu.Setup()
	}
}
