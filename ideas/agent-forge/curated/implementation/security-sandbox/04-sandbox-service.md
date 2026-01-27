# Part 4: Sandbox Service and Tool

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create sandbox service for execution management and the `execute_in_sandbox` tool for Coding Agent.

**Architecture:** Service layer orchestrates repository and runtime, handles org settings, validates tool access. Tool registered in existing registry pattern.

**Tech Stack:** Go, following patterns from `internal/service/` and `internal/tools/`

**Prerequisites:** Parts 2-3 (repository, runtime) completed

---

## Task 1: Create Sandbox Service

**Files:**
- Create: `internal/service/sandbox_service.go`
- Test: `internal/service/sandbox_service_test.go`

**Step 1: Write the failing test**

```go
// internal/service/sandbox_service_test.go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/sandbox"
)

func TestSandboxService_Execute(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := NewSandboxService(repo, runtime)

	ctx := context.Background()

	// Execute without org settings (should use defaults)
	req := &SandboxExecuteRequest{
		OrgID:     "org-123",
		ProjectID: "proj-456",
		TaskID:    "task-789",
		Runtime:   "python",
		Command:   []string{"python", "-c", "print('hello')"},
		Code:      "print('hello')",
	}

	result, err := svc.Execute(ctx, req)
	if err != nil {
		t.Fatalf("Execute() error = %v", err)
	}
	if result.Status != domain.StatusCompleted {
		t.Errorf("Status = %v, want completed", result.Status)
	}

	// Verify execution was logged
	execs, err := repo.ListExecutionsByProject(ctx, "proj-456")
	if err != nil {
		t.Fatalf("ListExecutionsByProject() error = %v", err)
	}
	if len(execs) != 1 {
		t.Errorf("len(execs) = %v, want 1", len(execs))
	}
}

func TestSandboxService_ToolDisabled(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := NewSandboxService(repo, runtime)

	ctx := context.Background()

	// Create settings with sandbox disabled
	settings := domain.NewDefaultOrgSandboxSettings("org-disabled")
	settings.DisabledTools = []string{"execute_in_sandbox"}
	repo.SaveSettings(ctx, settings)

	req := &SandboxExecuteRequest{
		OrgID:   "org-disabled",
		Runtime: "python",
		Command: []string{"python", "-c", "print('hello')"},
	}

	_, err := svc.Execute(ctx, req)
	if err == nil {
		t.Error("Execute() expected error for disabled tool")
	}
}

func TestSandboxService_RuntimeDisabled(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := NewSandboxService(repo, runtime)

	ctx := context.Background()

	// Create settings with only node enabled
	settings := domain.NewDefaultOrgSandboxSettings("org-node-only")
	settings.EnabledRuntimes = []string{"node"}
	repo.SaveSettings(ctx, settings)

	req := &SandboxExecuteRequest{
		OrgID:   "org-node-only",
		Runtime: "python", // Not enabled
		Command: []string{"python", "-c", "print('hello')"},
	}

	_, err := svc.Execute(ctx, req)
	if err == nil {
		t.Error("Execute() expected error for disabled runtime")
	}
}

func TestSandboxService_GetOrCreateSettings(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := NewSandboxService(repo, runtime)

	ctx := context.Background()

	// Get settings for org that doesn't exist yet
	settings, err := svc.GetOrCreateSettings(ctx, "new-org")
	if err != nil {
		t.Fatalf("GetOrCreateSettings() error = %v", err)
	}
	if settings.OrgID != "new-org" {
		t.Errorf("OrgID = %v, want new-org", settings.OrgID)
	}
	if settings.MemoryLimitMB != 512 {
		t.Errorf("MemoryLimitMB = %v, want 512 (default)", settings.MemoryLimitMB)
	}

	// Get again - should return same settings
	settings2, err := svc.GetOrCreateSettings(ctx, "new-org")
	if err != nil {
		t.Fatalf("GetOrCreateSettings() error = %v", err)
	}
	if settings2.MemoryLimitMB != 512 {
		t.Errorf("expected same settings to be returned")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run TestSandboxService -v`
Expected: FAIL - undefined: NewSandboxService

**Step 3: Write the service implementation**

```go
// internal/service/sandbox_service.go
package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/sandbox"
)

// SandboxExecuteRequest contains parameters for sandbox execution.
type SandboxExecuteRequest struct {
	OrgID     string
	ProjectID string
	TaskID    string
	Runtime   string
	Command   []string
	Code      string
	WorkDir   string
	Env       map[string]string
}

// SandboxService manages sandbox execution and configuration.
type SandboxService struct {
	repo    repository.SandboxRepository
	runtime sandbox.Runtime
}

// NewSandboxService creates a new sandbox service.
func NewSandboxService(repo repository.SandboxRepository, runtime sandbox.Runtime) *SandboxService {
	return &SandboxService{
		repo:    repo,
		runtime: runtime,
	}
}

// Execute runs code in the sandbox with org-specific limits.
func (s *SandboxService) Execute(ctx context.Context, req *SandboxExecuteRequest) (*domain.SandboxExecution, error) {
	// Get org settings (or defaults)
	settings, err := s.GetOrCreateSettings(ctx, req.OrgID)
	if err != nil {
		return nil, err
	}

	// Check if sandbox execution is disabled for this org
	for _, disabled := range settings.DisabledTools {
		if disabled == "execute_in_sandbox" {
			return nil, errors.New("sandbox execution is disabled for this organization")
		}
	}

	// Check if runtime is enabled
	runtimeEnabled := false
	for _, r := range settings.EnabledRuntimes {
		if r == req.Runtime {
			runtimeEnabled = true
			break
		}
	}
	if !runtimeEnabled {
		return nil, errors.New("runtime '" + req.Runtime + "' is not enabled for this organization")
	}

	// Create execution record
	execID := uuid.New().String()
	execution := &domain.SandboxExecution{
		ID:          execID,
		ProjectID:   req.ProjectID,
		AgentTaskID: req.TaskID,
		Runtime:     req.Runtime,
		Command:     joinCommand(req.Command),
		StartedAt:   time.Now(),
	}

	// Execute in sandbox
	result, err := s.runtime.Execute(ctx, &sandbox.ExecutionRequest{
		Runtime:   req.Runtime,
		Command:   req.Command,
		Code:      req.Code,
		WorkDir:   req.WorkDir,
		Env:       req.Env,
		Limits:    settings,
		ProjectID: req.ProjectID,
		TaskID:    req.TaskID,
	})

	// Update execution record with results
	execution.EndedAt = time.Now()
	if err != nil {
		execution.Status = domain.StatusKilled
		execution.Stderr = err.Error()
	} else {
		execution.ExitCode = result.ExitCode
		execution.Status = result.Status
		execution.Stdout = result.Stdout
		execution.Stderr = result.Stderr
		execution.MemoryUsedMB = result.MemoryUsedMB
		execution.CPUTimeSeconds = result.CPUTimeSeconds
		execution.WallTimeSeconds = result.WallTimeSeconds
		execution.WarningIssued = result.WarningIssued
	}

	// Save execution log (don't fail on save error)
	_ = s.repo.SaveExecution(ctx, execution)

	if err != nil {
		return execution, err
	}
	return execution, nil
}

// GetOrCreateSettings returns org sandbox settings, creating defaults if none exist.
func (s *SandboxService) GetOrCreateSettings(ctx context.Context, orgID string) (*domain.OrgSandboxSettings, error) {
	settings, err := s.repo.GetSettings(ctx, orgID)
	if err != nil {
		return nil, err
	}
	if settings != nil {
		return settings, nil
	}

	// Create default settings
	settings = domain.NewDefaultOrgSandboxSettings(orgID)
	if err := s.repo.SaveSettings(ctx, settings); err != nil {
		return nil, err
	}
	return settings, nil
}

// UpdateSettings updates org sandbox settings (admin only).
func (s *SandboxService) UpdateSettings(ctx context.Context, settings *domain.OrgSandboxSettings) error {
	if err := settings.Validate(); err != nil {
		return err
	}
	settings.UpdatedAt = time.Now()
	return s.repo.SaveSettings(ctx, settings)
}

// GetExecutionsByProject returns all sandbox executions for a project.
func (s *SandboxService) GetExecutionsByProject(ctx context.Context, projectID string) ([]*domain.SandboxExecution, error) {
	return s.repo.ListExecutionsByProject(ctx, projectID)
}

// GetExecutionsByTask returns all sandbox executions for a task.
func (s *SandboxService) GetExecutionsByTask(ctx context.Context, taskID string) ([]*domain.SandboxExecution, error) {
	return s.repo.ListExecutionsByTask(ctx, taskID)
}

func joinCommand(cmd []string) string {
	if len(cmd) == 0 {
		return ""
	}
	result := cmd[0]
	for i := 1; i < len(cmd); i++ {
		result += " " + cmd[i]
	}
	return result
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run TestSandboxService -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/sandbox_service.go internal/service/sandbox_service_test.go
git commit -m "feat(service): add SandboxService for execution management"
```

---

## Task 2: Create execute_in_sandbox Tool

**Files:**
- Create: `internal/tools/sandbox.go`
- Test: `internal/tools/sandbox_test.go`

**Step 1: Write the failing test**

```go
// internal/tools/sandbox_test.go
package tools

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/sandbox"
	"github.com/anthropics/agentic-platform/internal/service"
)

func TestExecuteInSandboxTool(t *testing.T) {
	// Setup
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)

	tool := NewExecuteInSandboxTool(svc)

	if tool.Name != "execute_in_sandbox" {
		t.Errorf("Name = %v, want execute_in_sandbox", tool.Name)
	}

	// Verify it's only available to coding agent
	if len(tool.AgentTypes) != 1 || tool.AgentTypes[0] != "coding" {
		t.Errorf("AgentTypes = %v, want [coding]", tool.AgentTypes)
	}

	// Execute tool
	ctx := context.Background()
	args := map[string]any{
		"runtime": "python",
		"command": []any{"python", "-c", "print('hello')"},
		"code":    "print('hello')",
		"orgId":   "org-123",
	}

	result, err := tool.Handler(ctx, args)
	if err != nil {
		t.Fatalf("Handler() error = %v", err)
	}

	execResult, ok := result.(*domain.SandboxExecution)
	if !ok {
		t.Fatalf("result type = %T, want *domain.SandboxExecution", result)
	}
	if execResult.Status != domain.StatusCompleted {
		t.Errorf("Status = %v, want completed", execResult.Status)
	}
}

func TestExecuteInSandboxTool_ValidationErrors(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)
	tool := NewExecuteInSandboxTool(svc)

	ctx := context.Background()

	tests := []struct {
		name    string
		args    map[string]any
		wantErr string
	}{
		{
			name: "missing runtime",
			args: map[string]any{
				"command": []any{"python", "test.py"},
				"orgId":   "org-123",
			},
			wantErr: "runtime is required",
		},
		{
			name: "missing command",
			args: map[string]any{
				"runtime": "python",
				"orgId":   "org-123",
			},
			wantErr: "command is required",
		},
		{
			name: "invalid runtime",
			args: map[string]any{
				"runtime": "haskell",
				"command": []any{"runhaskell", "test.hs"},
				"orgId":   "org-123",
			},
			wantErr: "invalid runtime",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := tool.Handler(ctx, tt.args)
			if err == nil {
				t.Error("expected error")
				return
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/tools/... -run TestExecuteInSandbox -v`
Expected: FAIL - undefined: NewExecuteInSandboxTool

**Step 3: Write the tool implementation**

```go
// internal/tools/sandbox.go
package tools

import (
	"context"
	"errors"

	"github.com/anthropics/agentic-platform/internal/sandbox"
	"github.com/anthropics/agentic-platform/internal/service"
)

// NewExecuteInSandboxTool creates the execute_in_sandbox tool for Coding Agent.
func NewExecuteInSandboxTool(svc *service.SandboxService) *Tool {
	return &Tool{
		Name:        "execute_in_sandbox",
		Description: "Execute code in an isolated sandbox environment. Use this to run tests, validate code, or execute scripts. The sandbox has no network access and limited resources.",
		Parameters: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"runtime": map[string]any{
					"type":        "string",
					"description": "The runtime environment: node, python, or go",
					"enum":        []string{"node", "python", "go"},
				},
				"command": map[string]any{
					"type":        "array",
					"items":       map[string]any{"type": "string"},
					"description": "Command to execute as array of strings, e.g. [\"python\", \"test.py\"]",
				},
				"code": map[string]any{
					"type":        "string",
					"description": "Code content to write to a file before execution (optional)",
				},
				"workDir": map[string]any{
					"type":        "string",
					"description": "Working directory inside container (default: /workspace)",
				},
				"env": map[string]any{
					"type":        "object",
					"description": "Environment variables to set",
				},
			},
			"required": []string{"runtime", "command"},
		},
		AgentTypes: []string{"coding"}, // Only available to Coding Agent
		Handler:    createSandboxHandler(svc),
	}
}

func createSandboxHandler(svc *service.SandboxService) ToolHandler {
	return func(ctx context.Context, args map[string]any) (any, error) {
		// Extract and validate runtime
		runtime, ok := args["runtime"].(string)
		if !ok || runtime == "" {
			return nil, errors.New("runtime is required")
		}
		if _, valid := sandbox.ValidRuntimes[runtime]; !valid {
			return nil, errors.New("invalid runtime: " + runtime)
		}

		// Extract and validate command
		cmdAny, ok := args["command"].([]any)
		if !ok || len(cmdAny) == 0 {
			return nil, errors.New("command is required")
		}
		command := make([]string, len(cmdAny))
		for i, c := range cmdAny {
			s, ok := c.(string)
			if !ok {
				return nil, errors.New("command must be array of strings")
			}
			command[i] = s
		}

		// Extract optional fields
		code, _ := args["code"].(string)
		workDir, _ := args["workDir"].(string)

		var env map[string]string
		if envAny, ok := args["env"].(map[string]any); ok {
			env = make(map[string]string)
			for k, v := range envAny {
				if s, ok := v.(string); ok {
					env[k] = s
				}
			}
		}

		// Get context values (set by agent executor)
		orgID, _ := ctx.Value("orgId").(string)
		if orgID == "" {
			orgID, _ = args["orgId"].(string) // Fallback for testing
		}
		projectID, _ := ctx.Value("projectId").(string)
		taskID, _ := ctx.Value("taskId").(string)

		// Execute
		return svc.Execute(ctx, &service.SandboxExecuteRequest{
			OrgID:     orgID,
			ProjectID: projectID,
			TaskID:    taskID,
			Runtime:   runtime,
			Command:   command,
			Code:      code,
			WorkDir:   workDir,
			Env:       env,
		})
	}
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/tools/... -run TestExecuteInSandbox -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/tools/sandbox.go internal/tools/sandbox_test.go
git commit -m "feat(tools): add execute_in_sandbox tool for Coding Agent"
```

---

## Task 3: Register Tool in Registry

**Files:**
- Modify: `internal/tools/registry.go` (or initialization code)

**Step 1: Read current registry initialization**

Find where tools are registered (likely in `cmd/api/main.go` or similar).

**Step 2: Add sandbox tool registration**

Add to initialization code:

```go
// In main.go or setup function
sandboxRepo := memory.NewSandboxRepository()
sandboxRuntime := sandbox.NewDockerRuntime()
sandboxService := service.NewSandboxService(sandboxRepo, sandboxRuntime)
registry.Register(tools.NewExecuteInSandboxTool(sandboxService))
```

**Step 3: Verify coding agent can access the tool**

```go
// Add test to verify
func TestRegistry_CodingAgentHasSandbox(t *testing.T) {
	registry := NewRegistry()
	// ... register sandbox tool

	codingTools := registry.ListForAgent("coding")
	found := false
	for _, tool := range codingTools {
		if tool.Name == "execute_in_sandbox" {
			found = true
			break
		}
	}
	if !found {
		t.Error("execute_in_sandbox not available to coding agent")
	}
}
```

**Step 4: Run all tool tests**

Run: `go test ./internal/tools/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/tools/registry.go
git commit -m "feat(tools): register execute_in_sandbox in tool registry"
```

---

## Summary

After completing Part 4, you will have:

**Created Files:**
- `internal/service/sandbox_service.go` - Service layer
- `internal/service/sandbox_service_test.go` - Service tests
- `internal/tools/sandbox.go` - Tool implementation
- `internal/tools/sandbox_test.go` - Tool tests

**Features Implemented:**
- Execution with org-specific limits
- Tool access control (disabled tools check)
- Runtime validation (enabled runtimes check)
- Automatic execution logging
- Default settings creation

**Next:** Proceed to [05-api-integration.md](./05-api-integration.md)
