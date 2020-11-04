package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"io/ioutil"
	"os"
)

var _ = Describe("CAPI", func() {
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
			pathToFile("config/capi"),
		}
		valueFiles = []string{
			pathToFile("tests/ytt/capi/capi-values.yml"),
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

	Context("Secrets", func() {
		Context("when using quarks secrets", func() {
			BeforeEach(func() {
				data = map[string]interface{}{}
				data["quarks_secret.enable"] = true
			})
		})

		Context("when using k8s secrets", func() {
			BeforeEach(func() {
				data = map[string]interface{}{}
				data["quarks_secret.enable"] = false
				data["capi.cf_api_controllers_client_secret"] = "squirrel"
			})
			It("should have only k8s capi secrets",  func() {

				Expect(ctx).To(ProduceYAML(
					And(
						WithSecret("cf-api-controllers-client-secret", "cf-system").WithStringDataValue("password", "squirrel"),

						//WithSecret("cf-api-backup-metadata-generator-client-secret", "cf-system"),
						//WithSecret("cloud-controller-username-lookup-client-secret", "cf-system"),
						//WithSecret("capi-database-encryption-key-secret", "cf-system"),
					),
				))
			})

		})

	})

})
