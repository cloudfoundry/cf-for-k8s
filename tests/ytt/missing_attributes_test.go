package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Missing Attributes", func() {
	var ctx RenderingContext
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

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

	Context("when all required attributes are missing", func() {
		baseTemplateFiles := []string{
			pathToFile("config/get_missing_parameters.star"),
			pathToFile("config/check-required-arguments.yml"),
		}

		Context("when quarks secrets are disabled", func() {
			BeforeEach(func() {
				templateFiles = append(baseTemplateFiles,
					pathToFile("tests/ytt/quarks_secret/quarks_secret_disabled.yml"))
			})
			It("should list all the required attributes", func() {
				Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_domains", "app_registry.hostname", "app_registry.password", "app_registry.repository_prefix", "app_registry.username", "blobstore.secret_access_key", "capi.cc_username_lookup_client_secret", "capi.cf_api_controllers_client_secret", "capi.cf_api_backup_metadata_generator_client_secret", "capi.database.encryption_key", "capi.database.password", "cf_admin_password", "instance_index_env_injector_certificate.ca", "instance_index_env_injector_certificate.crt", "instance_index_env_injector_certificate.key", "system_certificate.crt", "system_certificate.key", "system_domain", "uaa.admin_client_secret", "uaa.database.password", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "uaa.login_secret", "workloads_certificate.crt", "workloads_certificate.key"\]`))
			})
		})

		Context("when quarks secrets are enabled", func() {
			BeforeEach(func() {
				templateFiles = append(baseTemplateFiles,
					pathToFile("tests/ytt/quarks_secret/quarks_secret_enabled.yml"))
			})

			It("should list all the required attributes", func() {
				Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_domains", "app_registry.hostname", "app_registry.password", "app_registry.repository_prefix", "app_registry.username", "blobstore.secret_access_key", "capi.database.password", "instance_index_env_injector_certificate.ca", "instance_index_env_injector_certificate.crt", "instance_index_env_injector_certificate.key", "system_certificate.crt", "system_certificate.key", "system_domain", "uaa.database.password", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "uaa.login_secret", "workloads_certificate.crt", "workloads_certificate.key"\]`))
			})
		})
	})

	Context("when some required attributes are missing", func() {
		BeforeEach(func() {
			templateFiles = []string{
				pathToFile("config/check-required-arguments.yml"),
				pathToFile("config/get_missing_parameters.star"),
			}

			valueFiles = []string{
				pathToFile("tests/ytt/missing_attributes/missing_attributes_values.yml"),
				pathToFile("tests/ytt/quarks_secret/quarks_secret_disabled.yml"),
			}
		})

		It("should complain about missing attributes", func() {
			Expect(ctx).To(ThrowError(`The following required data.values parameters are missing: \["app_registry.username", "capi.cc_username_lookup_client_secret", "capi.cf_api_controllers_client_secret", "capi.cf_api_backup_metadata_generator_client_secret", "cf_admin_password", "instance_index_env_injector_certificate.ca", "instance_index_env_injector_certificate.crt", "instance_index_env_injector_certificate.key", "system_certificate.key", "uaa.encryption_key.passphrase", "uaa.jwt_policy.signing_key", "uaa.login.service_provider.certificate", "uaa.login.service_provider.key", "uaa.login_secret", "workloads_certificate.crt"\]`))
		})
	})

	Context("when all required attributes are present", func() {
		BeforeEach(func() {
			templateFiles = []string{
				pathToFile("config"),
			}

			valueFiles = []string{
				pathToFile("sample-cf-install-values.yml"),
				pathToFile("tests/ytt/quarks_secret/quarks_secret_disabled.yml"),
			}
		})

		It("should not complain", func() {
			Expect(ctx).To(ProduceYAML(WithNamespace("cf-system")))
		})
	})
})
