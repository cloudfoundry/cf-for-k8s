package matchers

import (
	"fmt"
	"github.com/onsi/gomega/format"
	"github.com/onsi/gomega/types"
	appsv1 "k8s.io/api/apps/v1"
)

type WithStatefulSetMatcher struct {
	name, namespace, errorMsg, errorMsgNotted string
	matcher                                   types.GomegaMatcher
	metas                                     []types.GomegaMatcher
	failedMatcher                             types.GomegaMatcher
}

func WithStatefulSet(name, ns string) *WithStatefulSetMatcher {
	meta := NewObjectMetaMatcher()
	meta.WithNamespace(ns)
	var metas []types.GomegaMatcher
	metas = append(metas, meta)
	return &WithStatefulSetMatcher{name: name, metas: metas}
}

func (matcher *WithStatefulSetMatcher) Match(actual interface{}) (bool, error) {
	docsMap, ok := actual.(map[string]interface{})
	if !ok {
		return false, fmt.Errorf("YAMLDocument must be passed a map[string]interface{}. Got\n%s", format.Object(actual, 1))
	}

	statefulSet, ok := docsMap["StatefulSet/"+matcher.name]
	if !ok {
		return false, nil
	}

	typedStatefulSet, _ := statefulSet.(*appsv1.StatefulSet)

	for _, meta := range matcher.metas {
		ok, err := meta.Match(typedStatefulSet.ObjectMeta)
		if !ok || err != nil {
			matcher.failedMatcher = meta
			return ok, err
		}
	}
	return true, nil
}

func (matcher *WithStatefulSetMatcher) FailureMessage(actual interface{}) string {
	if matcher.failedMatcher == nil {
		msg := fmt.Sprintf(
			"FailureMessage: A statefulset with name %q doesnt exist",
			matcher.name,
		)
		return msg
	}
	return matcher.failedMatcher.FailureMessage(actual)
}

func (matcher *WithStatefulSetMatcher) NegatedFailureMessage(actual interface{}) string {
	if matcher.failedMatcher == nil {
		msg := fmt.Sprintf(
			"FailureMessage: A statefulset with name %q exists",
			matcher.name,
		)
		return msg
	}
	return matcher.failedMatcher.NegatedFailureMessage(actual)
}
