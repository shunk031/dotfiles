package main

import (
	"fmt"
	"log"
)

const DOTFILES_LOGO = `
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

const GITHUB_REPOSITORY = "shunk031/dotfiles"
const DOTFILES_ORIGIN = "git@github.com:" + GITHUB_REPOSITORY + ".git"
const DOTFILES_DIRECTORY = "$HOME/.dotfiles"

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

func main() {
	fmt.Println(DOTFILES_LOGO)

	err := verifyOS()
	if err != nil {
		log.Fatal(err)
	}

}
