package configs_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestConfigs(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Optional Configs Suite")
}
