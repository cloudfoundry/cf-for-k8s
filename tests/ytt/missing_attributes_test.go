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
				pathToFile("config/get_missing_parameters.star"),
				pathToFile("config/check-required-arguments.yml"),
			}
		})

		It("should list all the required attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_domains", "app_registry.hostname", "app_registry.password", "app_registry.repository_prefix", "app_registry.username", "blobstore.secret_access_key", "capi.cc_username_lookup_client_secret", "capi.cf_api_controllers_client_secret", "capi.database.encryption_key", "capi.database.password", "cf_admin_password", "internal_certificate.ca", "internal_certificate.crt", "internal_certificate.key", "system_certificate.crt", "system_certificate.key", "system_domain", "uaa.admin_client_secret", "uaa.database.password", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "uaa.login_secret", "workloads_certificate.crt", "workloads_certificate.key"\]`))
		})
	})

	Context("when some required attributes are missing", func() {
		BeforeEach(func() {
			templates = []string{
				pathToFile("config/check-required-arguments.yml"),
				pathToFile("config/get_missing_parameters.star"),
				pathToFile("tests/ytt/missing_attributes/missing_attributes_values.yml"),
			}
		})

		It("should complain about missing attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_registry.username", "capi.cc_username_lookup_client_secret", "capi.cf_api_controllers_client_secret", "cf_admin_password", "internal_certificate.ca", "internal_certificate.crt", "internal_certificate.key", "system_certificate.key", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "uaa.login_secret", "workloads_certificate.crt"\]`))
		})
	})

	Context("when all required attributes are present", func() {
		BeforeEach(func() {
			templates = []string{
				pathToFile("config"),
				pathToFile("sample-cf-install-values.yml"),
			}
		})

		It("should not complain", func() {
			Expect(ctx).To(ProduceYAML(WithNamespace("cf-system")))
		})
	})
})
