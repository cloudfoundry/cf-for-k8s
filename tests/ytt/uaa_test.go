package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gstruct"
)

var _ = Describe("UAA", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

	BeforeEach(func() {
		templateFiles = []string{
			pathToFile("config/uaa"),
			pathToFile("config/namespaces.star"),
			pathToFile("config/quarks-secret/quarks-secret.star"),
		}

		valueFiles = []string{
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
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

	Context("given a database configuration", func() {
		BeforeEach(func() {
			data = map[string]interface{}{
				"system_namespace":  "cf-system",
				"uaa.database.port": "9999",
				"uaa.database.name": "some-name",
			}
		})

		It("should produce a correctly formatted jdbc connection string", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithDeployment("uaa", "cf-system"),
					WithConfigMap("uaa-config", "cf-system").WithData(
						gstruct.Keys{"uaa.yml": ContainSubstring("jdbc:postgresql://cf-db-postgresql.cf-db.svc.cluster.local:9999/some-name?sslmode=disable")}),
				),
			))
		})

		Context("secured with a certificate", func() {
			BeforeEach(func() {
				data["uaa.database.ca_cert"] = "some-cert"
			})

			It("should produce a correctly formatted jdbc connection string", func() {
				Expect(ctx).To(ProduceYAML(
					And(
						WithDeployment("uaa", "cf-system"),
						WithConfigMap("uaa-config", "cf-system").WithData(
							gstruct.Keys{"uaa.yml": ContainSubstring("jdbc:postgresql://cf-db-postgresql.cf-db.svc.cluster.local:9999/some-name?sslmode=verify-full&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory")}),
					),
				))
			})
		})

		Context("for an external database", func() {
			BeforeEach(func() {
				data["uaa.database.host"] = "a.database.some.where"
			})

			It("should produce a correctly formatted jdbc connection string", func() {
				Expect(ctx).To(ProduceYAML(
					And(
						WithDeployment("uaa", "cf-system"),
						WithConfigMap("uaa-config", "cf-system").WithData(
							gstruct.Keys{"uaa.yml": ContainSubstring("jdbc:postgresql://a.database.some.where:9999/some-name?sslmode=disable")}),
					),
				))
			})
		})
	})

	Context("when using quarks secrets", func() {
		BeforeEach(func() {
			data = map[string]interface{}{}
			data["quarks_secret.enable"] = true
		})

		It("should render quarks secrets for uaa client secrets", func() {

			Expect(ctx).To(ProduceYAML(
				And(
					Not(WithSecret("uaa-admin-client-credentials", "cf-system")),
					WithQuarksSecret("uaa-admin-client-credentials", "cf-system"),
				),
			))
		})
	})
})
