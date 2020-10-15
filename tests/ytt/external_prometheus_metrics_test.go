package ytt

import (
	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("External Prometheus scraping access", func() {

	var ctx RenderingContext
	var data map[string]interface{}
	var templates []string

	BeforeEach(func() {
		templates = []string{
			pathToFile("config/capi"),
			pathToFile("config/metrics"),
			pathToFile("config/uaa"),
			pathToFile("config/namespaces.star"),
			pathToFile("config/ingress.lib.yml"),
			pathToFile("tests/ytt/capi/capi-values.yml"),
			pathToFile("tests/ytt/metrics/metrics-values.yml"),
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
		}
	})

	JustBeforeEach(func() {
		ctx = NewRenderingContext(templates...).WithData(data)
	})

	Context("disabled", func() {

		BeforeEach(func() {
			data = map[string]interface{}{
				"allow_prometheus_metrics_access": false,
			}
		})

		It("should not have Istio proxy inbound exclusion rule", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					Not(WithDeployment("cf-api-server", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9102"`)),
					Not(WithDeployment("metric-proxy", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9090"`)),
					Not(WithDeployment("uaa", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9102"`)),
				)))
		})
	})

	Context("enabled", func() {

		BeforeEach(func() {
			data = map[string]interface{}{
				"allow_prometheus_metrics_access": true,
			}
		})

		It("should have Istio proxy inbound exclusion rule", func() {
			Expect(ctx).To(ProduceYAML(
				And(
					WithDeployment("cf-api-server", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9102"`),
					WithDeployment("metric-proxy", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9090"`),
					WithDeployment("uaa", "cf-system").WithSpecYaml(`
                      template:
                        metadata:
                          annotations:
                            traffic.sidecar.istio.io/excludeInboundPorts: "9102"`),
				)))
		})
	})
})
