package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("External Blobstore", func() {

	var ctx RenderingContext
	var data map[string]string
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/minio"),
			pathToFile("tests/ytt/blobstore/blobstore-values.yml"),
		}
	})

	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...).WithData(data)
	})

	Context("disabled", func() {

		BeforeEach(func() {
			data = map[string]string{
				"blobstore.endpoint":          "http://cf-blobstore-minio.cf-blobstore.svc.cluster.local:9000",
				"blobstore.access_key_id":     "F4k3nuGo2PLQzN9ETk9VbNYx",
				"blobstore.secret_access_key": "F4k3zsYvUUaVDlsWtFM1EJyH",
			}
		})

		It("should have cf-blobstore namespace and cf-blobstore-minio deployment", func() {

			Expect(ctx).To(ProduceYAML(
				And(
					WithNamespace("cf-blobstore"),
					WithDeployment("cf-blobstore-minio", "cf-blobstore")),
			))
		})
	})

	Context("enabled", func() {

		BeforeEach(func() {
			data = map[string]string{
				"blobstore.endpoint":                "https://s3.eu-central-1.amazonaws.com/",
				"blobstore.region":                  "eu-central-1",
				"blobstore.access_key_id":           "nuGo2PLQzN9ETk9VbNYxF4k3",
				"blobstore.secret_access_key":       "ZsYvUUaVDlsWtFM1EJyHF4k3",
				"blobstore.package_directory_key":   "cc-packages-dbf5",
				"blobstore.droplet_directory_key":   "cc-droplets-dbf5",
				"blobstore.resource_directory_key":  "cc-resources-dbf5",
				"blobstore.buildpack_directory_key": "cc-buildpacks-dbf5",
				"blobstore.aws_signature_version":   "4",
			}
		})

		It("should not have cf-blobstore namespace and cf-blobstore-minio deployment", func() {

			Expect(ctx).To(ProduceYAML(
				And(
					Not(WithNamespace("cf-blobstore")),
					Not(WithDeployment("cf-blobstore-minio", "cf-blobstore")),
				)))
		})
	})
})
