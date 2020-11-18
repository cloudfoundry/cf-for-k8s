package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("System registry", func() {
	var ctx RenderingContext
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

	BeforeEach(func() {
		templateFiles = []string{
			pathToFile("config/system-registry.yml"),
			pathToFile("config/uaa"),
			pathToFile("config/namespaces.star"),
			pathToFile("config/quarks-secret/quarks-secret.star"),
		}

		valueFiles = []string{
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
			pathToFile("tests/ytt/system-registry/system-registry-values.yml"),
			pathToFile("tests/ytt/quarks_secret/quarks_secret_enabled.yml"),
		}
	})

	JustBeforeEach(func() {
		targetDir, err = ioutil.TempDir("", "")
		Expect(err).NotTo(HaveOccurred())

		ctx, err = NewRenderingContext(
			WithTargetDir(targetDir),
			WithTemplateFiles(templateFiles...),
			WithValueFiles(valueFiles...),
		)
		Expect(err).NotTo(HaveOccurred())
	})

	JustAfterEach(func() {
		err = os.RemoveAll(targetDir)
		Expect(err).NotTo(HaveOccurred())
	})

	Context("enabled", func() {
		It("should have the expected imagePullSecrets", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithSecret("system-registry-auth-secret", "").WithDataValue(
						".dockerconfigjson",
						[]byte(`{"auths":{"test.test":{"auth":"dGVzdC11c2VybmFtZTp0ZXN0LXBhc3N3b3Jk","password":"test-password","username":"test-username"}}}`),
					),
					WithDeployment("uaa", "cf-system").WithSpecYaml(`
                     template:
                       spec:
                         imagePullSecrets:
                         - name: system-registry-auth-secret`),
				),
			))
		})
	})
})
