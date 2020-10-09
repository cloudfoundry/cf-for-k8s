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
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_registry.username", "cc_username_lookup_client_secret", "cf_admin_password", "cf_api_controllers_client_secret", "cf_db.admin_password", "gateway.https_only", "internal_certificate.ca", "internal_certificate.key", "system_certificate.key", "uaa.database.adapter", "uaa.database.admin_client_secret", "uaa.database.host", "uaa.database.name", "uaa.database.port", "uaa.database.user", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.login_secret", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "workloads_certificate.ca"\]`))
		})

		FIt("should list exactly 40 missing required attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \[(?:"[\w_.]+"(?:, )?){40}\]`))
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
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_registry.username", "cc_username_lookup_client_secret", "cf_admin_password", "cf_api_controllers_client_secret", "cf_db.admin_password", "gateway.https_only", "internal_certificate.ca", "internal_certificate.key", "system_certificate.key", "uaa.database.adapter", "uaa.database.admin_client_secret", "uaa.database.host", "uaa.database.name", "uaa.database.port", "uaa.database.user", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.login_secret", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "workloads_certificate.ca"\]`))
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
