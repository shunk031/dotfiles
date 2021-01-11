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
		err = Execute(msg, "tar", "-zxf", archive, "--strip-components", "1", "-C", outputDir)
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

func execute(cmd string, arg ...string) error {
	if false {
		c := exec.Command(cmd, arg...)
		err := c.Run()

		return err

	} else {

		time.Sleep(2 * time.Second)

		return nil
	}
}

func Execute(msg string, cmd string, arg ...string) error {

	s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
	s.Prefix = "  ["
	s.Suffix = fmt.Sprintf("] %s", msg)

	s.Start()
	err := execute(cmd)
	s.Stop()

	printResult(msg, err)

	return err
}
