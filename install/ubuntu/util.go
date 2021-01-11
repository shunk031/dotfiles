package ubuntu

import (
	"fmt"
	"log"
	"os/exec"
	"shunk031/dotfiles/install/util"
)

func packageIsInstalled(pkg string) bool {
	err := exec.Command("dpkg", "-s", pkg)
	if err != nil {
		log.Println(err)
		return false
	}
	return true
}

type AptCmd struct {
}

func (a AptCmd) InstallWithExtraArgs(pkg string, pkgReadableName string, extraArgs string) {

	if !packageIsInstalled(pkg) {
		cmd := fmt.Sprintf("sudo apt-get install --allow-unauthenticated -qqy %s %s %s", extraArgs, pkg, pkgReadableName)
		//                                                suppress output ─┘│
		//                      assume "yes" as the answer to all prompts ──┘
		msg := fmt.Sprintf("Install %s", pkg)
		err := util.Execute(msg, "/bin/bash", "-c", cmd)
		if err != nil {
			log.Println(err)
		}

	} else {
		util.PrintSuccess(pkgReadableName)
	}
}

func (a AptCmd) Install(pkg string, pkgReadableName string) {
	a.InstallWithExtraArgs(pkg, pkgReadableName, "")
}

func (a AptCmd) Update() {

	// Resynchronize the package index files from their sources.
	msg := fmt.Sprintf("APT (update)")
	cmd := fmt.Sprintf("sudo apt-get update -qqy")
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Println(err)
	}

}

func (a AptCmd) Upgrade() {
	// Install the newest versions of all packages installed.
	msg := fmt.Sprintf("APT (upgrade)")

	cmdExport := fmt.Sprintf("export DEBIAN_FRONTEND=\"noninteractive\"")
	cmdApt := fmt.Sprintf("sudo apt-get -o Dpkg::Options::=\"--force-confnew\" upgrade -qqy")

	cmd := fmt.Sprintf("%s; %s", cmdExport, cmdApt)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Println(err)
	}
}

func (a AptCmd) AddPpa(repo string) {
	msg := fmt.Sprintf("APT (add apt repository)")
	cmd := fmt.Sprintf("sudo add-apt-repository -y ppa:%s", repo)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}
