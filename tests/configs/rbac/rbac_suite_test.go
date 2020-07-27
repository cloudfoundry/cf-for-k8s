package rbac

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestRBac(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "RBac Suite")
}
