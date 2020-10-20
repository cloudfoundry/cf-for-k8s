package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Networking", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/"),
			pathToFile("tests/ytt/networking/networking-values.yml"),
		}
	})

	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...).WithData(data)
	})

	Context("when the ingress_solution_provider is set to Istio", func() {
		BeforeEach(func() {
			data = map[string]interface{}{
				"networking.ingress_solution_provider": "istio",
			}
		})

		It("should produce Istio resources", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithDeployment("istiod", "istio-system"),
				),
			))
		})

		It("should not produce other ingress solution resources", func() {
			Expect(ctx).NotTo(ProduceYAML(
				And(
					WithDeployment("contour", "projectcontour"),
				),
			))
		})
	})

	Context("when the ingress_solution_provider is to Contour", func() {
		BeforeEach(func() {
			data = map[string]interface{}{
				"networking.ingress_solution_provider": "contour",
			}
		})

		It("should not produce other ingress solution resources", func() {
			Expect(ctx).NotTo(ProduceYAML(
				And(
					WithDeployment("istiod", "istio-system"),
				),
			))
		})
	})
})
