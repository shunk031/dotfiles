package macos

import "shunk031/dotfiles/install/util"

type XCode struct {
	util.Helper
}

func (x XCode) Install() {
	x.Print()

	x.installXCodeCommandLineTools()
	x.installXCode()
	x.setXCodeDeveloperDirectory()
}

func (x XCode) installXCodeCommandLineTools() {

}

func (x XCode) installXCode() {

}

func (x XCode) setXCodeDeveloperDirectory() {

}

func (x XCode) agreeWithXcodeLicence() {

}

func NewXCode() SetupMasOS {
	helper := util.Helper{"XCode"}
	return XCode{helper}
}
