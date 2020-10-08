package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gstruct"
)

var _ = Describe("UAA", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/uaa"),
			pathToFile("config/namespaces.star"),
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
		}
	})

	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...).WithData(data)
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
})
