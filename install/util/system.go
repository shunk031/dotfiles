package util

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"runtime"
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
	v1 := strings.Split(osVersion, ".")
	v2 := strings.Split(minOSVersion, ".")

	for i := 0; i < len(v1); i++ {
		if v1[i] < v2[i] {
			return false
		} else if v1[i] > v2[i] {
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
	tmpFile, err := ioutil.TempFile("/tmp/", "XXXXX")
	if err != nil {
		return err
	}
	defer os.Remove(tmpFile.Name())

	s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
	s.Suffix = fmt.Sprintf(" %s", msg)

	s.Start()
	err = execute(cmd)
	s.Stop()

	printResult(msg, err)

	return err
}
