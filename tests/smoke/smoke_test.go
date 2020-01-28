package smoke_test

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
)

const NamePrefix = "cf-for-k8s-smoke"

func GetRequiredEnvVar(envVarName string) string {
	value, ok := os.LookupEnv(envVarName)
	Expect(ok).To(BeTrue(), envVarName+" environment variable is required, but was not provided.")
	return value
}

var _ = Describe("Smoke Tests", func() {
	When("running cf push", func() {
		var (
			orgName    string
			appsDomain string
		)

		BeforeEach(func() {
			apiEndpoint := GetRequiredEnvVar("SMOKE_TEST_API_ENDPOINT")
			username := GetRequiredEnvVar("SMOKE_TEST_USERNAME")
			password := GetRequiredEnvVar("SMOKE_TEST_PASSWORD")
			appsDomain = GetRequiredEnvVar("SMOKE_TEST_APPS_DOMAIN")

			// Target CF and auth
			cfAPI := cf.Cf("api", "--skip-ssl-validation", apiEndpoint)
			Eventually(cfAPI).Should(Exit(0))

			// Authenticate
			Eventually(func() *Session {
				return cf.CfRedact(password, "auth", username, password).Wait()
			}, 1*time.Minute, 2*time.Second).Should(Exit(0))

			// Create an org and space and target
			orgName = generator.PrefixedRandomName(NamePrefix, "org")
			spaceName := generator.PrefixedRandomName(NamePrefix, "space")

			Eventually(cf.Cf("create-org", orgName)).Should(Exit(0))
			Eventually(cf.Cf("create-space", "-o", orgName, spaceName)).Should(Exit(0))
			Eventually(cf.Cf("target", "-o", orgName, "-s", spaceName)).Should(Exit(0))

			// Enable Docker Feature Flag
			Eventually(cf.Cf("enable-feature-flag", "diego_docker")).Should(Exit(0))
		})

		AfterEach(func() {
			// Delete the test org
			Eventually(func() *Session {
				return cf.Cf("delete-org", orgName, "-f").Wait()
			}, 5*time.Minute, 1*time.Second).Should(Exit(0))
		})

		It("creates a routable app pod in Kubernetes", func() {
			appName := generator.PrefixedRandomName(NamePrefix, "app")

			By("Pushing an app and checking that the CF CLI command succeeds")
			cfPush := cf.Cf("push", appName, "-o", "cloudfoundry/diego-docker-app")
			Eventually(cfPush).Should(Exit(0))

			By("Querying the app")
			var resp *http.Response

			Eventually(func() int {
				var err error
				resp, err = http.Get(fmt.Sprintf("http://%s.%s/env", appName, appsDomain))
				Expect(err).NotTo(HaveOccurred())
				return resp.StatusCode
			}, 5*time.Minute, 30*time.Second).Should(Equal(200))

			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())

			var appResponse struct {
				VcapServices string `json:"VCAP_SERVICES"`
			}

			json.Unmarshal(body, &appResponse)

			Expect(appResponse.VcapServices).NotTo(BeEmpty())
		})
	})
})
