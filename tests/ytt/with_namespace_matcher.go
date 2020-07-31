package ytt

import (
	"fmt"
	"github.com/onsi/gomega/format"
)

type WithNamespaceMatcher struct {
	name string
}

func WithNamespace(name string) *WithNamespaceMatcher {
	return &WithNamespaceMatcher{name}
}

func (matcher *WithNamespaceMatcher) Match(actual interface{}) (bool, error) {
	docsMap, ok := actual.(map[string]interface{})
	if !ok {
		return false, fmt.Errorf("YAMLDocument must be passed a map[string]interface{}. Got\n%s", format.Object(actual, 1))
	}

	_, ok = docsMap["Namespace/"+matcher.name]
	if !ok {
		return false, nil
	}

	return true, nil
}

func (matcher *WithNamespaceMatcher) FailureMessage(actual interface{}) string {
	msg := fmt.Sprintf(
		"FailureMessage: A namespace with name %q doesnt exist",
		matcher.name,
	)
	return msg
}

func (matcher *WithNamespaceMatcher) NegatedFailureMessage(actual interface{}) string {
	msg := fmt.Sprintf(
		"FailureMessage: A namespace with name %q exists",
		matcher.name,
	)
	return msg
}
