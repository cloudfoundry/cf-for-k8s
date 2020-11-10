package ytt

import (
	"fmt"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var templateBasePath string

func init() {
	SetDefaultEventuallyTimeout(10 * time.Second)

	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		panic("Could not initialize ytt package: can't find location of this file")
	}

	relative := filepath.Join(filepath.Dir(filename), "..", "..")
	abs, err := filepath.Abs(relative)
	if err != nil {
		panic(fmt.Sprintf("Could not initialize ytt package: %v", err))
	}

	templateBasePath = abs
}

func pathToFile(name string) string {
	return filepath.Join(templateBasePath, name)
}

func TestDeployment(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Config Test Suite")
}
