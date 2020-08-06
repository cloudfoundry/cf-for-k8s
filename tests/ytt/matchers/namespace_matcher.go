package matchers

import (
	"fmt"
	"github.com/onsi/gomega/format"
	"github.com/onsi/gomega/types"
	coreV1 "k8s.io/api/core/v1"
)

type NamespaceMatcher struct {
	stringData types.GomegaMatcher
	data       types.GomegaMatcher
	meta       *ObjectMetaMatcher

	executed types.GomegaMatcher
}

func RepresentingNamespace() *NamespaceMatcher {
	return &NamespaceMatcher{
		nil,
		nil,
		NewObjectMetaMatcher(),
		nil,
	}
}

func (matcher *NamespaceMatcher) WithName(name string) *NamespaceMatcher {
	matcher.meta.WithName(name)

	return matcher
}

func (matcher *NamespaceMatcher) Match(actual interface{}) (success bool, err error) {
	ns, ok := actual.(*coreV1.Namespace)
	if !ok {
		return false, fmt.Errorf("Expected a namespace. Got\n%s", format.Object(actual, 1))
	}

	matcher.executed = matcher.meta
	if pass, err := matcher.meta.Match(ns.ObjectMeta); !pass || err != nil {
		return pass, err
	}

	return true, nil
}

func (matcher *NamespaceMatcher) FailureMessage(actual interface{}) string {
	return matcher.executed.FailureMessage(actual)
}

func (matcher *NamespaceMatcher) NegatedFailureMessage(actual interface{}) string {
	return matcher.executed.NegatedFailureMessage(actual)
}
