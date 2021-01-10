package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/logrusorgru/aurora"
	"github.com/shirou/gopsutil/host"
)

func ask(msg string) string {
	printQuestion(msg)

	reader := bufio.NewReader(os.Stdin)
	response, err := reader.ReadString('\n')
	if err != nil {
		log.Fatal(err)
	}
	response = strings.TrimSpace(response)

	fmt.Println()
	return response
}

func askForConfirmation(msg string) bool {
	printQuestion(fmt.Sprintf("%s (y/n) ", msg))

	reader := bufio.NewReader(os.Stdin)
	for {
		response, err := reader.ReadString('\n')
		if err != nil {
			log.Fatal(err)
		}

		response = strings.ToLower(strings.TrimSpace(response))

		if response == "y" || response == "yes" {
			// fmt.Println()
			return true
		} else if response == "n" || response == "no" {
			// fmt.Println()
			return false
		}
	}
}

func cmdExists(c string) bool {
	cmd := exec.Command("command", "-v", c)
	if err := cmd.Run(); err != nil {
		log.Println(err)
		return false
	}
	return true
}

func extract(archive string, outputDir string) error {

	var err error
	if cmdExists("tar") {
		msg := fmt.Sprintf("Extract from %s", archive)
		err = execute(msg, "tar", "-zxf", archive, "--strip-components", "1", "-C", outputDir)
	}
	return err
}

func getOS() string {

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

func getOSVersion() string {
	os := getOS()

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

func isSupportedVersion(osVersion string, minOSVersion string) bool {
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

func printInPurple(s string) {
	fmt.Println(aurora.Magenta(s))
}

func printInGreen(s string) {
	fmt.Print(aurora.Green(s))
}

func printInYellow(s string) {
	fmt.Print(aurora.Yellow(s))
}

func printInRed(s string) {
	fmt.Print(aurora.Red(s))
}

func printQuestion(s string) {
	printInYellow(fmt.Sprintf("  [?] %s", s))
}

func printSuccess(s string) {
	printInGreen(fmt.Sprintf("  [✔] %s\n", s))
}

func printWarning(s string) {
	printInYellow(fmt.Sprintf("  [!] %s\n", s))
}

func printError(s string, e error) {
	printInRed(fmt.Sprintf("  [✖] %s %s\n", s, e))
}

func printResult(s string, err error) {
	if err != nil {
		printError(s, err)
	} else {
		printSuccess(s)
	}
}

func execute(msg string, cmd string, arg ...string) error {
	tmpFile, err := ioutil.TempFile("/tmp/", "XXXXX")
	if err != nil {
		return err
	}
	defer os.Remove(tmpFile.Name())

	if false {
		c := exec.Command(cmd, arg...)
		err := c.Run()
		return err

	} else {
		s := spinner.New(spinner.CharSets[9], 100*time.Millisecond)
		s.Suffix = fmt.Sprintf(" %s", msg)
		s.Start()

		time.Sleep(4 * time.Second)
		s.Stop()

		return nil
	}
}
