package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = FDescribe("CAPI", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/namespaces.star"),
			pathToFile("config/quarks-secret/quarks-secret.star"),
			pathToFile("tests/ytt/capi/capi-values.yml"),
			pathToFile("config/capi"),
		}
		data = map[string]interface{}{}
	})

	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...).WithData(data)
	})

	Context("Secrets", func() {
		Context("when using quarks secrets", func() {
			BeforeEach(func() {
				data["quarks_secret.enable"] = true
			})
		})

		Context("when using k8s secrets", func() {
			BeforeEach(func() {
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
