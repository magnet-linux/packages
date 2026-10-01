package packages_test

import (
	"context"
	"io/fs"
	"path/filepath"
	"strings"
	"testing"

	graphjsonnet "github.com/magnet-linux/magpkg/pkggraph/jsonnet"
)

// This integration test belongs to the tree, not to the package manager.
func TestPackageGraphs(t *testing.T) {
	err := filepath.WalkDir("..", func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if entry.Name() == ".git" || entry.Name() == "out" || entry.Name() == "_work" {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".jsonnet") {
			return nil
		}
		t.Run(path, func(t *testing.T) {
			graph, err := graphjsonnet.EvaluateFile(context.Background(), path,
				graphjsonnet.Options{ExtVars: map[string]string{"bootstrap-url": "file:///test/bootstrap.tar.zst"}})
			if err != nil {
				t.Fatal(err)
			}
			if len(graph.RootNames()) == 0 {
				t.Fatal("package graph exports no roots")
			}
		})
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
