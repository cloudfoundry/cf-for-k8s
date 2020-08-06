package matchers

import (
	"fmt"
	"os/exec"
	"reflect"
	"strings"

	. "github.com/onsi/ginkgo"
	"github.com/onsi/gomega/format"
	"github.com/onsi/gomega/gbytes"
	"github.com/onsi/gomega/gexec"
	"github.com/onsi/gomega/types"

	"k8s.io/client-go/kubernetes/scheme"
)

type ProduceYAMLMatcher struct {
	matcher  types.GomegaMatcher
	rendered string
}

func ProduceYAML(matcher types.GomegaMatcher) *ProduceYAMLMatcher {
	return &ProduceYAMLMatcher{matcher, ""}
}

func (matcher *ProduceYAMLMatcher) Match(actual interface{}) (bool, error) {
	rendering, ok := actual.(RenderingContext)
	if !ok {
		return false, fmt.Errorf("ProduceYAML must be passed a RenderingContext. Got\n%s", format.Object(actual, 1))
	}

	session, err := renderWithData(rendering.templates, rendering.data)
	if err != nil || session.ExitCode() != 0 {
		return false, fmt.Errorf("render error, exit status={%v}, command={%s}, error={%v}", session.ExitCode(), session.Command, err)
	}

	matcher.rendered = string(session.Out.Contents())
	docsMap, err := parseYAML(session.Out)
	if err != nil {
		return false, err
	}

	return matcher.matcher.Match(docsMap)
}

func (matcher *ProduceYAMLMatcher) FailureMessage(actual interface{}) string {
	msg := fmt.Sprintf(
		"FailureMessage: There is a problem with this YAML:\n\n%s\n\n%s",
		matcher.rendered,
		matcher.matcher.FailureMessage(actual),
	)
	return msg
}

func (matcher *ProduceYAMLMatcher) NegatedFailureMessage(actual interface{}) string {
	msg := fmt.Sprintf(
		"NegatedFailureMessage: There is a problem with this YAML:\n\n%s\n\n%s",
		matcher.rendered,
		matcher.matcher.NegatedFailureMessage(actual),
	)
	return msg
}

func renderWithData(templates []string, data map[string]string) (*gexec.Session, error) {
	var args []string
	for _, template := range templates {
		args = append(args, "-f", template)
	}

	for k, v := range data {
		args = append(args, "-v", fmt.Sprintf("%s=%s", k, v))
	}

	command := exec.Command("ytt", args...)
	session, err := gexec.Start(command, nil, GinkgoWriter)
	if err != nil {
		return session, err
	}

	return session.Wait(), nil
}

func parseYAML(yaml *gbytes.Buffer) (interface{}, error) {
	// TODO: Look at extending UniversalDeserializer Scheme with CRDs.
	decode := scheme.Codecs.UniversalDeserializer().Decode

	apiObjects := map[string]interface{}{}

	// for each document
	docStrings := strings.Split(string(yaml.Contents()), "---")
	for _, docString := range docStrings {
		// Checks for empty documents
		if docString == "" {
			continue
		}

		obj, gk, err := decode([]byte(docString), nil, nil)
		if err != nil {
			return nil, err
		}

		apiObjects[gk.Kind+"/"+reflect.ValueOf(obj).Elem().FieldByName("Name").String()] = obj
	}

	return apiObjects, nil
}
