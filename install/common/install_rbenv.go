package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installRbenv() {
	rbenvDir := filepath.Join(os.Getenv("HOME"), ".rbenv")
	rbenvURL := "https://github.com/rbenv/rbenv.git"

	msg := fmt.Sprintf("Install to %s", rbenvDir)
	cmdRm := fmt.Sprintf("rm -rf %s", rbenvDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", rbenvURL, rbenvDir)
	cmdCd := fmt.Sprintf("cd %s", rbenvDir)
	cmdConfigure := fmt.Sprintf("src/configure")
	cmdMake := fmt.Sprintf("make -C src")

	cmd := fmt.Sprintf("%s; %s; %s; %s; %s", cmdRm, cmdGit, cmdCd, cmdConfigure, cmdMake)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func installRubyBuild() {
	rubyBuildDir := filepath.Join(os.Getenv("HOME"), ".rbenv", "plugins", "ruby-build")
	rubyBuildURL := "https://github.com/rbenv/ruby-build.git"

	msg := fmt.Sprintf("Install to %s", rubyBuildDir)
	cmdRm := fmt.Sprintf("rm -rf %s", rubyBuildDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", rubyBuildURL, rubyBuildDir)

	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallRbenv() {
	util.PrintInPurple("rbenv and ruby-build")
	installRbenv()
	installRubyBuild()

}
