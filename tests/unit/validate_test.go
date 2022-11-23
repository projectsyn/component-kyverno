package main

import (
	"fmt"
	"io/ioutil"
	"regexp"
	"testing"

	"github.com/instrumenta/kubeval/kubeval"
	"github.com/stretchr/testify/require"
)

var (
	testPath = "../../compiled/kyverno/kyverno"
)

// kubeval is unable to validate some of the resources
// we need to explicitly ignore them
func skipValidation(path string) bool {
	ignore := []*regexp.Regexp{
		regexp.MustCompile(fmt.Sprintf("%s/00_crds", testPath)),
		regexp.MustCompile(fmt.Sprintf("%s/10_monitoring", testPath)),
		regexp.MustCompile(fmt.Sprintf("%s/10_pod-disruption-budget", testPath)),
		regexp.MustCompile(fmt.Sprintf("%s/80_policies.yaml", testPath)),
		regexp.MustCompile(`.*/apiextensions.k8s.io_v1_customresourcedefinition.*\.yaml`),
	}
	for _, iv := range ignore {
		if iv.MatchString(path) {
			return true
		}
	}
	return false
}

func validate(t *testing.T, path string) {
	files, err := ioutil.ReadDir(path)
	require.NoError(t, err)
	for _, file := range files {
		filePath := fmt.Sprintf("%s/%s", path, file.Name())
		if skipValidation(filePath) {
			t.Logf("Skipped validation for: %s", filePath)
			continue
		}

		if file.IsDir() {
			validate(t, filePath)
		} else {
			data, err := ioutil.ReadFile(filePath)
			require.NoError(t, err)

			conf := kubeval.NewDefaultConfig()
			res, err := kubeval.Validate(data, conf)
			require.NoError(t, err)
			for _, r := range res {
				if len(r.Errors) > 0 {
					t.Errorf("%s", filePath)
				}
				for _, e := range r.Errors {
					t.Errorf("\t %s", e)
				}
			}
		}
	}
}
func Test_Validate(t *testing.T) {
	validate(t, testPath)
}
