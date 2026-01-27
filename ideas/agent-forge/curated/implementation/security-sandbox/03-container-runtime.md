# Part 3: Container Runtime

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create Docker-based container runtime with security restrictions for isolated code execution.

**Architecture:** Provider pattern (like LLM providers) - interface for runtime abstraction, Docker implementation with security hardening. Mock mode for testing without Docker.

**Tech Stack:** Go, Docker SDK, following patterns from `internal/llm/provider.go`

**Prerequisites:** Part 2 (repository) completed

---

## Task 1: Create Runtime Interface

**Files:**
- Create: `internal/sandbox/runtime.go`

**Step 1: Write the interface and types**

```go
// internal/sandbox/runtime.go
package sandbox

import (
	"context"
	"errors"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// ValidRuntimes maps runtime names to container images
var ValidRuntimes = map[string]string{
	"node":   "node:20-slim",
	"python": "python:3.11-slim",
	"go":     "golang:1.21-alpine",
}

// ExecutionRequest contains parameters for sandbox execution.
type ExecutionRequest struct {
	Runtime   string                     // node, python, go
	Command   []string                   // command to execute
	Code      string                     // code content to write
	WorkDir   string                     // working directory in container
	Env       map[string]string          // environment variables
	Limits    *domain.OrgSandboxSettings // resource limits
	ProjectID string                     // for audit logging
	TaskID    string                     // for audit logging
}

// Validate checks that the request is valid.
func (r *ExecutionRequest) Validate() error {
	if r.Runtime == "" {
		return errors.New("runtime is required")
	}
	if _, ok := ValidRuntimes[r.Runtime]; !ok {
		return errors.New("invalid runtime: " + r.Runtime)
	}
	if len(r.Command) == 0 {
		return errors.New("command is required")
	}
	return nil
}

// ExecutionResult contains the outcome of sandbox execution.
type ExecutionResult struct {
	ExitCode        int
	Stdout          string
	Stderr          string
	Status          domain.SandboxExecutionStatus
	MemoryUsedMB    int
	CPUTimeSeconds  float64
	WallTimeSeconds float64
	WarningIssued   bool
}

// Runtime defines the interface for sandbox execution backends.
type Runtime interface {
	// Execute runs code in an isolated container and returns the result.
	Execute(ctx context.Context, req *ExecutionRequest) (*ExecutionResult, error)

	// Cleanup releases any resources held by the runtime.
	Cleanup() error

	// Available checks if the runtime backend is available.
	Available() bool
}
```

**Step 2: Verify it compiles**

Run: `go build ./internal/sandbox/...`
Expected: Success

**Step 3: Commit**

```bash
git add internal/sandbox/runtime.go
git commit -m "feat(sandbox): add Runtime interface and request/result types"
```

---

## Task 2: Create ExecutionRequest Validation Tests

**Files:**
- Create: `internal/sandbox/runtime_test.go`

**Step 1: Write the test**

```go
// internal/sandbox/runtime_test.go
package sandbox

import "testing"

func TestExecutionRequest_Validate(t *testing.T) {
	tests := []struct {
		name    string
		req     ExecutionRequest
		wantErr bool
		errMsg  string
	}{
		{
			name: "valid request",
			req: ExecutionRequest{
				Runtime: "python",
				Command: []string{"python", "test.py"},
				Code:    "print('hello')",
			},
			wantErr: false,
		},
		{
			name: "missing runtime",
			req: ExecutionRequest{
				Command: []string{"python", "test.py"},
			},
			wantErr: true,
			errMsg:  "runtime is required",
		},
		{
			name: "empty command",
			req: ExecutionRequest{
				Runtime: "python",
				Command: []string{},
			},
			wantErr: true,
			errMsg:  "command is required",
		},
		{
			name: "invalid runtime",
			req: ExecutionRequest{
				Runtime: "haskell",
				Command: []string{"runhaskell", "test.hs"},
			},
			wantErr: true,
			errMsg:  "invalid runtime",
		},
		{
			name: "valid node",
			req: ExecutionRequest{
				Runtime: "node",
				Command: []string{"node", "index.js"},
			},
			wantErr: false,
		},
		{
			name: "valid go",
			req: ExecutionRequest{
				Runtime: "go",
				Command: []string{"go", "run", "main.go"},
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.req.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
			if tt.wantErr && err != nil && tt.errMsg != "" {
				if err.Error() != tt.errMsg && !contains(err.Error(), tt.errMsg) {
					t.Errorf("error = %v, want to contain %v", err, tt.errMsg)
				}
			}
		})
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || (len(s) > len(substr) && containsHelper(s, substr)))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
```

**Step 2: Run tests**

Run: `go test ./internal/sandbox/... -run TestExecutionRequest -v`
Expected: PASS

**Step 3: Commit**

```bash
git add internal/sandbox/runtime_test.go
git commit -m "test(sandbox): add ExecutionRequest validation tests"
```

---

## Task 3: Create Docker Runtime with Mock Mode

**Files:**
- Create: `internal/sandbox/docker_runtime.go`
- Modify: `internal/sandbox/runtime_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/sandbox/runtime_test.go
import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
)

func TestDockerRuntime_Execute_MockMode(t *testing.T) {
	runtime := NewDockerRuntime(WithMockMode(true))

	ctx := context.Background()
	req := &ExecutionRequest{
		Runtime: "python",
		Command: []string{"python", "-c", "print('hello')"},
		Code:    "print('hello')",
		Limits:  domain.NewDefaultOrgSandboxSettings("org-123"),
	}

	result, err := runtime.Execute(ctx, req)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}
	if result.ExitCode != 0 {
		t.Errorf("ExitCode = %v, want 0", result.ExitCode)
	}
	if result.Status != domain.StatusCompleted {
		t.Errorf("Status = %v, want completed", result.Status)
	}
	if result.Stdout == "" {
		t.Error("expected non-empty stdout in mock mode")
	}
}

func TestDockerRuntime_Available_MockMode(t *testing.T) {
	runtime := NewDockerRuntime(WithMockMode(true))
	if !runtime.Available() {
		t.Error("mock runtime should always be available")
	}
}

func TestDockerRuntime_ValidationError(t *testing.T) {
	runtime := NewDockerRuntime(WithMockMode(true))

	ctx := context.Background()
	req := &ExecutionRequest{
		Runtime: "",
		Command: []string{"python"},
	}

	_, err := runtime.Execute(ctx, req)
	if err == nil {
		t.Error("expected validation error for empty runtime")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/sandbox/... -run TestDockerRuntime -v`
Expected: FAIL - undefined: NewDockerRuntime

**Step 3: Write the Docker runtime**

```go
// internal/sandbox/docker_runtime.go
package sandbox

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/image"
	"github.com/docker/docker/client"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// DockerRuntime implements Runtime using Docker containers.
type DockerRuntime struct {
	client   *client.Client
	mockMode bool
}

// DockerOption configures the Docker runtime.
type DockerOption func(*DockerRuntime)

// WithMockMode enables mock mode for testing without Docker.
func WithMockMode(mock bool) DockerOption {
	return func(r *DockerRuntime) {
		r.mockMode = mock
	}
}

// NewDockerRuntime creates a new Docker-based sandbox runtime.
func NewDockerRuntime(opts ...DockerOption) *DockerRuntime {
	r := &DockerRuntime{}
	for _, opt := range opts {
		opt(r)
	}
	return r
}

// initClient lazily initializes the Docker client.
func (r *DockerRuntime) initClient() error {
	if r.mockMode || r.client != nil {
		return nil
	}
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return fmt.Errorf("failed to create docker client: %w", err)
	}
	r.client = cli
	return nil
}

func (r *DockerRuntime) Execute(ctx context.Context, req *ExecutionRequest) (*ExecutionResult, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Mock mode for testing
	if r.mockMode {
		return &ExecutionResult{
			ExitCode:        0,
			Stdout:          "mock output\n",
			Stderr:          "",
			Status:          domain.StatusCompleted,
			WallTimeSeconds: 0.1,
		}, nil
	}

	if err := r.initClient(); err != nil {
		return nil, err
	}

	startTime := time.Now()
	imageName := ValidRuntimes[req.Runtime]

	// Create temp directory for code
	tmpDir, err := os.MkdirTemp("", "sandbox-*")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(tmpDir)

	// Write code to temp directory
	if req.Code != "" {
		codeFile := filepath.Join(tmpDir, "code."+getExtension(req.Runtime))
		if err := os.WriteFile(codeFile, []byte(req.Code), 0644); err != nil {
			return nil, fmt.Errorf("failed to write code: %w", err)
		}
	}

	// Calculate resource limits
	limits := req.Limits
	if limits == nil {
		limits = domain.NewDefaultOrgSandboxSettings("")
	}

	// Container configuration with security restrictions
	containerConfig := &container.Config{
		Image:           imageName,
		Cmd:             req.Command,
		WorkingDir:      "/workspace",
		Env:             mapToEnv(req.Env),
		NetworkDisabled: true, // No network access per design
		User:            "nobody", // Non-root execution
	}

	// Host configuration with resource limits
	hostConfig := &container.HostConfig{
		Binds: []string{tmpDir + ":/workspace:ro"},
		Resources: container.Resources{
			Memory:     int64(limits.MemoryLimitMB) * 1024 * 1024,
			MemorySwap: int64(limits.MemoryLimitMB) * 1024 * 1024, // No swap
			NanoCPUs:   int64(limits.CPUCores * 1e9),
			PidsLimit:  ptrInt64(int64(limits.MaxProcesses)),
		},
		ReadonlyRootfs: true,
		SecurityOpt:    []string{"no-new-privileges"},
		CapDrop:        []string{"ALL"},
		Tmpfs: map[string]string{
			"/tmp": fmt.Sprintf("size=%dm,mode=1777", limits.DiskLimitMB),
		},
	}

	// Pull image if needed (timeout 30s)
	pullCtx, pullCancel := context.WithTimeout(ctx, 30*time.Second)
	defer pullCancel()
	reader, err := r.client.ImagePull(pullCtx, imageName, image.PullOptions{})
	if err == nil {
		io.Copy(io.Discard, reader)
		reader.Close()
	}

	// Create container
	resp, err := r.client.ContainerCreate(ctx, containerConfig, hostConfig, nil, nil, "")
	if err != nil {
		return nil, fmt.Errorf("failed to create container: %w", err)
	}
	containerID := resp.ID
	defer r.client.ContainerRemove(context.Background(), containerID, container.RemoveOptions{Force: true})

	// Start container
	if err := r.client.ContainerStart(ctx, containerID, container.StartOptions{}); err != nil {
		return nil, fmt.Errorf("failed to start container: %w", err)
	}

	// Wait for completion with timeout
	timeout := time.Duration(limits.TimeoutSeconds) * time.Second
	waitCtx, waitCancel := context.WithTimeout(ctx, timeout)
	defer waitCancel()

	statusCh, errCh := r.client.ContainerWait(waitCtx, containerID, container.WaitConditionNotRunning)

	var result ExecutionResult
	select {
	case err := <-errCh:
		if err != nil {
			// Timeout or other error - kill container
			r.client.ContainerKill(context.Background(), containerID, "SIGKILL")
			result.Status = domain.StatusTimeout
			result.WallTimeSeconds = time.Since(startTime).Seconds()
			return &result, nil
		}
	case status := <-statusCh:
		result.ExitCode = int(status.StatusCode)
	}

	// Capture logs
	logs, err := r.client.ContainerLogs(ctx, containerID, container.LogsOptions{
		ShowStdout: true,
		ShowStderr: true,
	})
	if err == nil {
		defer logs.Close()
		var stdout bytes.Buffer
		io.Copy(&stdout, logs)
		result.Stdout = stdout.String()
	}

	result.WallTimeSeconds = time.Since(startTime).Seconds()
	result.Status = domain.StatusCompleted
	if result.ExitCode != 0 {
		result.Status = domain.StatusKilled
	}

	return &result, nil
}

func (r *DockerRuntime) Cleanup() error {
	if r.client != nil {
		return r.client.Close()
	}
	return nil
}

func (r *DockerRuntime) Available() bool {
	if r.mockMode {
		return true
	}
	if err := r.initClient(); err != nil {
		return false
	}
	_, err := r.client.Ping(context.Background())
	return err == nil
}

func mapToEnv(m map[string]string) []string {
	if m == nil {
		return nil
	}
	env := make([]string, 0, len(m))
	for k, v := range m {
		env = append(env, k+"="+v)
	}
	return env
}

func getExtension(runtime string) string {
	switch runtime {
	case "python":
		return "py"
	case "node":
		return "js"
	case "go":
		return "go"
	default:
		return "txt"
	}
}

func ptrInt64(v int64) *int64 {
	return &v
}
```

**Step 4: Run tests**

Run: `go test ./internal/sandbox/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/sandbox/docker_runtime.go internal/sandbox/runtime_test.go
git commit -m "feat(sandbox): add DockerRuntime with mock mode and security restrictions"
```

---

## Task 4: Verify Build and All Tests

**Step 1: Run linter**

Run: `go vet ./internal/sandbox/...`
Expected: No errors

**Step 2: Build**

Run: `go build ./internal/sandbox/...`
Expected: Success

**Step 3: Run all tests**

Run: `go test ./internal/sandbox/... -v`
Expected: All PASS

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat(sandbox): complete container runtime with Docker integration"
```

---

## Summary

After completing Part 3, you will have:

**Created Files:**
- `internal/sandbox/runtime.go` - Interface and types
- `internal/sandbox/docker_runtime.go` - Docker implementation
- `internal/sandbox/runtime_test.go` - Test coverage

**Security Features Implemented:**
- Network disabled (`NetworkDisabled: true`)
- Non-root execution (`User: "nobody"`)
- Read-only root filesystem
- Dropped all capabilities
- Resource limits (memory, CPU, processes)
- Ephemeral tmpfs for temp storage
- No swap allowed

**Next:** Proceed to [04-sandbox-service.md](./04-sandbox-service.md)
