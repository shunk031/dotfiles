package util

import (
	"fmt"
	"log"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/shirou/gopsutil/host"
)

func VerifyOS() error {
	const minimumMacosVersion = "10.10"
	const minimumUbuntuVersion = "18.04"

	osName := GetOS()
	osVersion := GetOSVersion()

	if osName == "macos" {
		if IsSupportedVersion(osVersion, minimumMacosVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for macOS %s", minimumMacosVersion)
		}
	} else if osName == "ubuntu" {
		if IsSupportedVersion(osVersion, minimumUbuntuVersion) {
			return nil
		} else {
			return fmt.Errorf("Sorry, this script is intended only for Ubuntu %s+", minimumUbuntuVersion)
		}
	} else {
		return fmt.Errorf("Sorry, this script is intended only for macOS and Ubuntu")
	}
}

func CmdExists(c string) bool {
	cmd := exec.Command("command", "-v", c)
	if err := cmd.Run(); err != nil {
		log.Println(err)
		return false
	}
	return true
}

func extract(archive string, outputDir string) error {

	var err error
	if CmdExists("tar") {
		msg := fmt.Sprintf("Extract from %s", archive)
		cmd := fmt.Sprintf("tar -zxf %s --strip-components 1 -C %s", archive, outputDir)
		err = Execute(msg, cmd)
	}
	return err
}

func GetOS() string {

	var os string

	kernelName := runtime.GOOS

	switch kernelName {
	case "darwin":
		os = "macos"

	case "linux":
		platform, _, _, err := host.PlatformInformation()
		if err != nil {
			log.Fatal(err)
		}
		os = platform

	default:
		os = kernelName
	}

	return os
}

func GetOSVersion() string {
	os := GetOS()

	var version string
	var err error
	if os == "macos" {
		cmd := exec.Command("sw_vers", "-productVersion")
		ver, err := cmd.Output()
		if err != nil {
			log.Fatal(err)
		}
		version = strings.TrimRight(string(ver), "\n")

	} else if os == "linux" {
		_, _, version, err = host.PlatformInformation()
		if err != nil {
			log.Fatal(err)
		}
	}
	return version
}

func IsSupportedVersion(osVersion string, minOSVersion string) bool {
	v1x := strings.Split(osVersion, ".")
	v2x := strings.Split(minOSVersion, ".")

	for i := 0; i < len(v1x); i++ {
		v1, err := strconv.Atoi(v1x[i])
		if err != nil {
			log.Fatal(err)
		}

		v2, err := strconv.Atoi(v2x[i])
		if err != nil {
			log.Fatal(err)
		}

		if v1 < v2 {
			return false
		} else if v1 > v2 {
			return true
		}
	}

	return false
}

func execute(cmd string) error {

	if false {
		c := exec.Command("/bin/bash", "-c", cmd)
		err := c.Run()

		return err

	} else {

		time.Sleep(5 * time.Second)

		return nil
	}
}

func Execute(msg string, cmd string) error {

	s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
	s.Prefix = "  ["
	// s.Suffix = fmt.Sprintf("] %s", msg)
	s.Suffix = fmt.Sprintf("] %s", cmd)

	s.Start()
	err := execute(cmd)
	s.Stop()

	printResult(msg, err)

	return err
}
