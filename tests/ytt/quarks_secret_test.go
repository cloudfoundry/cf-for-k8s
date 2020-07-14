package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("QuarksSecret", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

	BeforeEach(func() {
		targetDir, err = ioutil.TempDir("", "")
		Expect(err).NotTo(HaveOccurred())

		templateFiles = []string{
			pathToFile("config/namespaces.star"),
			pathToFile("config/quarks-secret/quarks-secret.star"),
			pathToFile("config/quarks-secret"),
		}
		valueFiles = []string{
			pathToFile("config/values"),
			pathToFile("sample-cf-install-values.yml"),
		}
	})

	JustBeforeEach(func() {
		ctx, err = NewRenderingContext(
			WithData(data),
			WithTargetDir(targetDir),
			WithTemplateFiles(templateFiles...),
			WithValueFiles(valueFiles...),
		)
		Expect(err).NotTo(HaveOccurred())
	})

	AfterEach(func() {
		err = os.RemoveAll(targetDir)
		Expect(err).NotTo(HaveOccurred())
	})

	Context("when quarks secrets is not specified", func() {
		BeforeEach(func() {
			data = map[string]interface{}{}
		})

		It("should not have a deployment for quarks secret", func() {
			Expect(ctx).To(ProduceYAML(
				Not(WithDeployment("cf-quarks-secret", "cf-system")),
			))
		})
	})

	Context("when quarks secrets is specified", func() {
		BeforeEach(func() {
			data = map[string]interface{}{}
			data["quarks_secret.enable"] = true
		})

		It("should have a deployment for quarks secret", func() {
			Expect(ctx).To(ProduceYAML(
				WithDeployment("cf-quarks-secret", "cf-system"),
			))
		})
		// MAYBE TODO: Add check for the actual CRD?
	})
})
