package util

import "testing"

func TestCmdExists(t *testing.T) {

	if !CmdExists("ls") {
		t.Fatal("Test failed")
	}

	if CmdExists("command-probably-never-exist") {
		t.Fatal("Test failed")
	}
}

func TestGetOS(t *testing.T) {
	if GetOS() != "macos" {
		t.Fatal("Test failed")
	}
}

func TestGetOSVersion(t *testing.T) {

}

func TestIsSupportedVersion(t *testing.T) {
	if IsSupportedVersion("10.00", "11.00") {
		t.Fatal("Test failed")
	}

	if IsSupportedVersion("08.98", "12.54") {
		t.Fatal("Test failed")
	}

	if !IsSupportedVersion("108.98", "12.54") {
		t.Fatal("Test failed")
	}

	if !IsSupportedVersion("108.98.86", "098.54.784") {
		t.Fatal("Test failed")
	}
}

func TestExecute(t *testing.T) {

}
