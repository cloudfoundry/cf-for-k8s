package rbac_test

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("RBac", func() {
	var (
		args          []string
		repoDir       string
		outfile       *os.File
		templatedPath string = "/tmp/cf-for-k8s.yml"
	)
	BeforeEach(func() {
		currentDirectory, err := os.Getwd()
		repoDir = filepath.Dir(filepath.Dir(filepath.Dir(currentDirectory)))

		command := exec.Command(filepath.Join(repoDir, "hack", "generate-values.sh"),
			"--cf-domain", "dummy-domain",
		)
		valuesFile, err := os.Create("/tmp/dummy-domain-values-1.yml")
		Expect(err).NotTo(HaveOccurred())
		defer valuesFile.Close()
		command.Stdout = valuesFile

		err = command.Start()
		Expect(err).NotTo(HaveOccurred())

		print("generating fake values...")
		command.Wait()
		print(" [done]\n")

		args = []string{
			"-f", "../../../config",
			"-f", "/tmp/dummy-domain-values-1.yml",
		}
		outfile, err = os.Create(templatedPath)
		Expect(err).NotTo(HaveOccurred())
		defer outfile.Close()
		command = exec.Command("ytt", args...)
		session, err := Start(command, outfile, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		Eventually(session, 20*time.Second).Should(Exit(0),
			fmt.Sprintf("ytt failed on base with output %s", session.Err.Contents()))
	})
	Describe("permissions", func() {

		It("should not include cluster-admin", func() {
			output, err := ioutil.ReadFile(outfile.Name())
			Expect(err).ToNot(HaveOccurred())
			Expect(string(output)).NotTo(ContainSubstring("cluster-admin"))
		})
	})
})
