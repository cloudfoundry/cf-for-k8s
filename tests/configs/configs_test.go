package configs_test

import (
	"crypto/md5"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Optional Configs", func() {
	Describe("Check optional configs", func() {
		var (
			args     []string
			baseHash [16]byte
			repoDir  string
		)

		BeforeEach(func() {
			currentDirectory, err := os.Getwd()
			repoDir = filepath.Dir(filepath.Dir(currentDirectory))

			command := exec.Command(filepath.Join(repoDir, "hack", "generate-values.sh"),
				"--cf-domain", "dummy-domain",
			)
			outfile, err := os.Create("/tmp/dummy-domain-values.yml")
			Expect(err).NotTo(HaveOccurred())
			defer outfile.Close()
			command.Stdout = outfile

			err = command.Start()
			Expect(err).NotTo(HaveOccurred())

			print("generating fake values...")
			command.Wait()
			print(" [done]\n")

			args = []string{
				"-f", "../../config",
				"-f", "/tmp/dummy-domain-values.yml",
			}
			command = exec.Command("ytt", args...)
			session, err := Start(command, ioutil.Discard, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
			Eventually(session, 10*time.Second).Should(Exit(0),
				fmt.Sprintf("ytt failed on base with output %s", session.Err.Contents()))
			baseHash = md5.Sum(session.Out.Contents())
		})

		It("should load each optional config file", func() {
			currentDirectory, err := os.Getwd()
			Expect(err).ToNot(HaveOccurred())

			configDirectory := filepath.Join(filepath.Dir(filepath.Dir(currentDirectory)), "config-optional")

			count := 0
			filepath.Walk(configDirectory, func(path string, info os.FileInfo, err error) error {

				basename := info.Name()
				if !strings.HasSuffix(basename, ".yml") {
					return nil
				}
				fmt.Printf("Test file %s\n", basename)
				finalArgs := append(args, "-f", path)
				command := exec.Command("ytt", finalArgs...)

				session, err := Start(command, ioutil.Discard, GinkgoWriter)
				Expect(err).NotTo(HaveOccurred())
				session.Wait(10 * time.Second)
				Eventually(session).Should(Exit(0),
					fmt.Sprintf("ytt failed on %s with output %s", path, session.Err.Contents()))
				newHash := md5.Sum(session.Out.Contents())
				Expect(newHash).NotTo(Equal(baseHash), fmt.Sprintf("optional file %s had no effect", basename))
				count += 1

				return nil
			})
			Expect(count).To(BeNumerically(">=", 1))
		})
	})
})
