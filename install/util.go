package main

import (
	"log"
	"os/exec"
	"runtime"

	"github.com/shirou/gopsutil/host"
)

func getOS() string {

	var os string

	kernel_name := runtime.GOOS

	switch kernel_name {
	case "darwin":
		os = "macos"

	case "linux":
		platform, _, _, err := host.PlatformInformation()
		if err != nil {
			log.Fatal(err)
		}
		os = platform

	default:
		os = kernel_name
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
		version = string(ver)
	} else if os == "linux" {
		_, _, version, err = host.PlatformInformation()
		if err != nil {
			log.Fatal(err)
		}
	}
	return version
}

func isSupportedVersion(osVersion string, minOSVersion string) bool {
	return false
}
