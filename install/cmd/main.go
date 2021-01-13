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

const (
	repository = "shunk031/dotfiles"
	version    = "0.0.1"
)

var revision = "HEAD"

func main() {
	fmt.Println(dotfilesLogo)

	var (
		// DotfilesOrigin     = "git@github.com:" + repository + ".git"
		DotfilesDirectory  = filepath.Join(os.Getenv("HOME"), ".dotfiles")
		DotfilesTarballURL = filepath.Join("https://github.com", repository, "tarball/master")
		IsSkipQuestions    = false
	)

	err := util.VerifyOS()
	if err != nil {
		log.Fatal(err)
	}

	util.DownloadDotfiles(
		DotfilesDirectory,
		DotfilesTarballURL,
		IsSkipQuestions,
	)

	util.PrintInPurple("\n• Installs")

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
