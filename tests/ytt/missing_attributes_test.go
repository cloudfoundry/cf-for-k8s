package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Missing Attributes", func() {

	var ctx RenderingContext
	var templates []string


	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...)
	})

	Context("when all required attributes are missing", func() {
		BeforeEach(func() {
			templates = []string{
				pathToFile("config/check-required-arguments.yml"),
			}
		})

		It("should list all the required attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["system_domain", "app_domains", "cf_admin_password", "system_certificate.crt", "system_certificate.key", "system_certificate.ca", "workloads_certificate.crt", "workloads_certificate.key", "workloads_certificate.ca", "gateway.https_only", "app_registry.hostname", "app_registry.repository_prefix", "app_registry.username", "app_registry.password", "capi.database.adapter", "capi.database.encryption_key", "capi.database.host", "capi.database.port", "capi.database.user", "capi.database.password", "capi.database.name", "uaa.database.adapter", "uaa.database.host", "uaa.database.port", "uaa.database.user", "uaa.database.password", "uaa.database.name"\]`))
		})

		FIt("should list exactly 27 missing required attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \[(?:"[\w_.]+"(?:, )?){27}\]`))
		})
	})

	Context("when some required attributes are missing", func() {
		BeforeEach(func() {
			templates = []string{
				pathToFile("config/check-required-arguments.yml"),
				pathToFile("tests/ytt/missing_attributes/missing_attributes-values.yml"),
			}
		})

		FIt("should complain about missing attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["cf_admin_password", "system_certificate.key", "workloads_certificate.ca", "gateway.https_only", "app_registry.username", "uaa.database.adapter", "uaa.database.host", "uaa.database.port", "uaa.database.user", "uaa.database.name"\]`))
		})
	})

	Context("when all required attributes are present", func() {
		BeforeEach(func() {
			templates = []string{
				pathToFile("config/namespaces.star"),
				pathToFile("config/system-namespace.yml"),
				pathToFile("tests/ytt/missing_attributes/all-required-attributes-present-values.yml"),
			}
		})

		FIt("should not complain", func() {
			Expect(ctx).To(ProduceYAML(WithNamespace("cf-system")))
		})
	})
})
