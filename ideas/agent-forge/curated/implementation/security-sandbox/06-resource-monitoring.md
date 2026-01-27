# Part 6: Resource Monitoring

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement 80% resource warning threshold and graceful degradation per design doc.

**Architecture:** Add resource monitoring during container execution, callback mechanism for warnings, result marking.

**Tech Stack:** Go, Docker SDK stats API

**Prerequisites:** Part 3 (container runtime) completed

---

## Task 1: Add Warning Callback to Docker Runtime

**Files:**
- Modify: `internal/sandbox/docker_runtime.go`
- Modify: `internal/sandbox/runtime_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/sandbox/runtime_test.go
func TestDockerRuntime_ResourceWarning(t *testing.T) {
	runtime := NewDockerRuntime(WithMockMode(true))

	warningReceived := false
	runtime.SetWarningCallback(func(resource string, usage float64) {
		warningReceived = true
		if usage < 0.8 {
			t.Errorf("warning at %v, expected >= 0.8", usage)
		}
		if resource != "memory" {
			t.Errorf("resource = %v, want memory", resource)
		}
	})

	// Simulate 85% memory usage in mock mode
	runtime.SetMockResourceUsage(0.85)

	ctx := context.Background()
	req := &ExecutionRequest{
		Runtime: "python",
		Command: []string{"python", "-c", "print('hello')"},
		Limits:  domain.NewDefaultOrgSandboxSettings("org-123"),
	}

	result, err := runtime.Execute(ctx, req)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}
	if !warningReceived {
		t.Error("expected warning callback at 85% usage")
	}
	if !result.WarningIssued {
		t.Error("expected WarningIssued = true")
	}
}

func TestDockerRuntime_NoWarningBelowThreshold(t *testing.T) {
	runtime := NewDockerRuntime(WithMockMode(true))

	warningReceived := false
	runtime.SetWarningCallback(func(resource string, usage float64) {
		warningReceived = true
	})

	// 70% - below threshold
	runtime.SetMockResourceUsage(0.70)

	ctx := context.Background()
	req := &ExecutionRequest{
		Runtime: "python",
		Command: []string{"python", "-c", "print('hello')"},
		Limits:  domain.NewDefaultOrgSandboxSettings("org-123"),
	}

	result, err := runtime.Execute(ctx, req)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}
	if warningReceived {
		t.Error("unexpected warning at 70% usage")
	}
	if result.WarningIssued {
		t.Error("expected WarningIssued = false")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/sandbox/... -run TestDockerRuntime_ResourceWarning -v`
Expected: FAIL - runtime.SetWarningCallback undefined

**Step 3: Add warning callback to runtime**

```go
// Add to internal/sandbox/docker_runtime.go

// ResourceWarningCallback is called when resource usage exceeds 80%
type ResourceWarningCallback func(resource string, usageRatio float64)

// Add fields to DockerRuntime
type DockerRuntime struct {
	client            *client.Client
	mockMode          bool
	warningCallback   ResourceWarningCallback
	mockResourceUsage float64 // For testing
}

// SetWarningCallback sets the callback for resource warnings
func (r *DockerRuntime) SetWarningCallback(cb ResourceWarningCallback) {
	r.warningCallback = cb
}

// SetMockResourceUsage sets simulated resource usage for testing
func (r *DockerRuntime) SetMockResourceUsage(ratio float64) {
	r.mockResourceUsage = ratio
}

// Update Execute method - in mock mode:
func (r *DockerRuntime) Execute(ctx context.Context, req *ExecutionRequest) (*ExecutionResult, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Mock mode for testing
	if r.mockMode {
		result := &ExecutionResult{
			ExitCode:        0,
			Stdout:          "mock output\n",
			Stderr:          "",
			Status:          domain.StatusCompleted,
			WallTimeSeconds: 0.1,
		}

		// Check mock resource usage for warning
		if r.mockResourceUsage >= 0.8 {
			result.WarningIssued = true
			if r.warningCallback != nil {
				r.warningCallback("memory", r.mockResourceUsage)
			}
		}

		return result, nil
	}

	// ... rest of real implementation
}
```

**Step 4: Run tests**

Run: `go test ./internal/sandbox/... -run TestDockerRuntime_ResourceWarning -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/sandbox/docker_runtime.go internal/sandbox/runtime_test.go
git commit -m "feat(sandbox): add 80% resource warning callback"
```

---

## Task 2: Add Real Resource Monitoring in Docker Runtime

**Files:**
- Modify: `internal/sandbox/docker_runtime.go`

**Step 1: Add stats monitoring during execution**

In the real (non-mock) Execute path, add resource monitoring:

```go
// Add to Execute method, after container starts but before wait completes

// Start resource monitoring goroutine
warningThreshold := 0.8
monitorDone := make(chan struct{})
go func() {
	defer close(monitorDone)
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	memoryLimit := int64(limits.MemoryLimitMB) * 1024 * 1024

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			stats, err := r.client.ContainerStatsOneShot(ctx, containerID)
			if err != nil {
				continue
			}

			// Parse memory usage from stats
			var statsData struct {
				MemoryStats struct {
					Usage uint64 `json:"usage"`
				} `json:"memory_stats"`
			}
			if err := json.NewDecoder(stats.Body).Decode(&statsData); err != nil {
				stats.Body.Close()
				continue
			}
			stats.Body.Close()

			usageRatio := float64(statsData.MemoryStats.Usage) / float64(memoryLimit)
			result.MemoryUsedMB = int(statsData.MemoryStats.Usage / 1024 / 1024)

			if usageRatio >= warningThreshold && !result.WarningIssued {
				result.WarningIssued = true
				if r.warningCallback != nil {
					r.warningCallback("memory", usageRatio)
				}
			}
		}
	}
}()

// ... wait for container ...

// Stop monitoring
close(monitorDone) // or use context cancellation
```

**Step 2: Verify build**

Run: `go build ./internal/sandbox/...`
Expected: Success

**Step 3: Commit**

```bash
git add internal/sandbox/docker_runtime.go
git commit -m "feat(sandbox): add real-time resource monitoring during execution"
```

---

## Task 3: Run All Tests and Final Verification

**Step 1: Run all sandbox tests**

Run: `go test ./internal/sandbox/... -v`
Expected: All PASS

**Step 2: Run all tests**

Run: `go test ./... -v`
Expected: All PASS

**Step 3: Run linter**

Run: `go vet ./...`
Expected: No errors

**Step 4: Build entire project**

Run: `go build ./...`
Expected: Success

**Step 5: Final commit**

```bash
git add -A
git commit -m "feat(sandbox): complete security sandbox implementation

Implements container-based code execution sandbox per design doc:
- OrgSandboxSettings and SandboxExecution domain models
- Repository interface with in-memory implementation
- Docker runtime with security restrictions
- SandboxService for execution management
- execute_in_sandbox tool for Coding Agent
- HTTP endpoints for settings management
- 80% resource warning threshold
- Network isolation, non-root execution, resource limits"
```

---

## Summary

After completing Part 6, you will have:

**Enhanced Features:**
- Warning callback at 80% resource usage
- Real-time resource monitoring during execution
- Memory usage tracking in results
- `WarningIssued` flag in execution results

**Design Doc Compliance:**
- 80% threshold warning ✅
- Graceful degradation signal ✅
- 100% hard kill (via Docker limits) ✅

---

## Complete Implementation Summary

The sandbox system is now fully implemented:

| Component | Status |
|-----------|--------|
| Domain models | ✅ Complete |
| Repository | ✅ Complete |
| Container runtime | ✅ Complete |
| Service layer | ✅ Complete |
| Tool registration | ✅ Complete |
| API endpoints | ✅ Complete |
| Resource monitoring | ✅ Complete |

**Security Features:**
- Network disabled
- Non-root execution
- Read-only root filesystem
- All capabilities dropped
- Resource limits enforced
- Ephemeral storage only

**Admin Controls:**
- Enable/disable sandbox per org
- Configure resource limits
- Enable/disable runtimes
- View execution history
