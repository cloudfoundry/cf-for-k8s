package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("System registry", func() {

	var ctx RenderingContext
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/system-registry.yml"),
			pathToFile("config/uaa"),
			pathToFile("config/ingress.lib.yml"),
			pathToFile("config/namespaces.star"),
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
			pathToFile("tests/ytt/system-registry/system-registry-values.yml"),
		}
		ctx = NewRenderingContext(templates...)
	})

	Context("enabled", func() {

		It("should have the expected imagePullSecrets", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithSecret("system-registry-auth-secret").WithDataValue(
						".dockerconfigjson",
						[]byte(`{"auths":{"test.test":{"auth":"dGVzdC11c2VybmFtZTp0ZXN0LXBhc3N3b3Jk","password":"test-password","username":"test-username"}}}`),
					),
					WithDeployment("uaa", "cf-system").WithSpecYaml(`
                      template:
                        spec:
                          imagePullSecrets:
                          - name: system-registry-auth-secret`),
				)))
		})
	})
})
