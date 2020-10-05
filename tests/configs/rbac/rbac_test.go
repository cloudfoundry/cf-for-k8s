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
		args               []string
		repoDir            string
		outfile            *os.File
		internalValuesPath string = "/tmp/internal-values.yml"
		templatedPath      string = "/tmp/cf-for-k8s.yml"
	)

	BeforeEach(func() {
		currentDirectory, err := os.Getwd()
		Expect(err).NotTo(HaveOccurred())

		repoDir = filepath.Dir(filepath.Dir(filepath.Dir(currentDirectory)))

		By("generating internal values")
		command := exec.Command(filepath.Join(repoDir, "hack", "generate-internal-values.sh"),
			"--values-file", filepath.Join(repoDir, "sample-cf-install-values", "kind.yml"),
		)
		internalValuesFile, err := os.Create(internalValuesPath)
		Expect(err).NotTo(HaveOccurred())
		defer internalValuesFile.Close()
		command.Stdout = internalValuesFile

		err = command.Start()
		Expect(err).NotTo(HaveOccurred())

		err = command.Wait()
		Expect(err).NotTo(HaveOccurred())

		By("rendering templates")
		args = []string{
			"-f", "../../../config",
			"-f", internalValuesPath,
			"-f", filepath.Join(repoDir, "sample-cf-install-values", "kind.yml"),
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
				"yq failed to parse rendered manifest")
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
				"yq failed to parse rendered manifest")
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
