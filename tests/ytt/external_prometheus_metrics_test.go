package ytt

import (
	"io/ioutil"
	"os"

	. "code.cloudfoundry.org/yttk8smatchers/matchers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("External Prometheus scraping access", func() {
	var ctx RenderingContext
	var data map[string]interface{}
	var templateFiles []string
	var valueFiles []string
	var targetDir string
	var err error

	BeforeEach(func() {
		templateFiles = []string{
			pathToFile("config/capi"),
			pathToFile("config/metrics"),
			pathToFile("config/uaa"),
			pathToFile("config/namespaces.star"),
			pathToFile("config/quarks-secret/quarks-secret.star"),
		}

		valueFiles = []string{
			pathToFile("tests/ytt/capi/capi-values.yml"),
			pathToFile("tests/ytt/metrics/metrics-values.yml"),
			pathToFile("tests/ytt/uaa/uaa-values.yml"),
		}
	})

	JustBeforeEach(func() {
		targetDir, err = ioutil.TempDir("", "")
		Expect(err).NotTo(HaveOccurred())

		ctx, err = NewRenderingContext(
			WithData(data),
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
				),
			))
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
				),
			))
		})
	})
})
