package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("External DB", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

	BeforeEach(func() {
		templateFiles = []string{
			pathToFile("config/postgres"),
		}

		valueFiles = []string{
			pathToFile("tests/ytt/postgres/postgres-values.yml"),
		}
	})

	JustBeforeEach(func() {
		targetDir, err = ioutil.TempDir("", "")
		Expect(err).NotTo(HaveOccurred())

		ctx, err = NewRenderingContext(
			WithData(data),
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

	Context("disabled", func() {
		BeforeEach(func() {
			data = map[string]interface{}{
				"cf_db.admin_password":   "vz9o2hbkh6x7ztnd6ua6",
				"capi.database.password": "9v5ljlmxje8uv32gwl5q",
				"uaa.database.password":  "yevxad9e0pvgc8l6osnt",
				"capi.database.host":     "",
				"uaa.database.host":      "",
			}
		})

		It("should have cf-db namespace and cf-db-postgresql statefulset", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithNamespace("cf-db"),
					WithStatefulSet("cf-db-postgresql", "cf-db"),
				),
			))
		})
	})

	Context("enabled", func() {
		BeforeEach(func() {
			data = map[string]interface{}{
				"cf_db.admin_password":   "vz9o2hbkh6x7ztnd6ua6",
				"capi.database.password": "9v5ljlmxje8uv32gwl5q",
				"uaa.database.password":  "yevxad9e0pvgc8l6osnt",
				"capi.database.host":     "foo.bar",
				"uaa.database.host":      "foo.bar",
			}
		})

		It("should not have cf-db* namespace/statefulset", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					Not(WithNamespace("cf-db")),
					Not(WithStatefulSet("cf-db-postgresql", "cf-db")),
				),
			))
		})
	})
})
