package rbac_test

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
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
			"-f", "../app_registry.yml",
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
			containsClusterAdmin := strings.Contains(string(output), "cluster-admin")
			Expect(containsClusterAdmin).To(BeFalse())
		})

		It("cluster roles should not contain wildcard for the core api group", func() {
			command := exec.Command("yq", `select(.kind == "ClusterRole") | .rules[] | select(.apiGroups[] == "")`, outfile.Name())
			session, err := Start(command, nil, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
			Eventually(session, 40*time.Second).Should(Exit(0),
				"yq failed to parse rendered manifest. Note that this project uses python yq")
			dec := json.NewDecoder(strings.NewReader(string(session.Out.Contents())))
			for {
				var rule Rule

				err := dec.Decode(&rule)
				if err == io.EOF {
					// all done
					break
				}
				if err != nil {
					log.Fatal(err)
				}
				Expect(rule.Resources).NotTo(ContainElement("*"))
			}
		})

		It("disallows escalating permissions via rbac.authorization.k8s.io clusterroles", func() {
			command := exec.Command("yq", `select(.kind == "ClusterRole") | .rules[] | select(.apiGroups[] == "rbac.authorization.k8s.io")`, outfile.Name())
			session, err := Start(command, nil, GinkgoWriter)
			Expect(err).NotTo(HaveOccurred())
			Eventually(session, 40*time.Second).Should(Exit(0),
				"yq failed to parse rendered manifest. Note that this project uses python yq")
			dec := json.NewDecoder(strings.NewReader(string(session.Out.Contents())))
			for {
				var rule Rule

				err := dec.Decode(&rule)
				if err == io.EOF {
					// all done
					break
				}
				if err != nil {
					log.Fatal(err)
				}
				denyList := []string{"*", "create", "update", "patch"}
				for _, deniedVerb := range denyList {
					Expect(rule.Verbs).NotTo(ContainElement(deniedVerb))
				}
			}
		})

	})
})

type Rule struct {
	APIGroups []string `json:"apiGroups"`
	Resources []string `json:"resources"`
	Verbs     []string `json:"verbs"`
}
