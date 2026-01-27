# Part 5: API Integration

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add HTTP endpoints for sandbox settings management and wire sandbox into agent executor.

**Architecture:** Follow existing handler patterns, add to routes. Executor uses tool registry for tool calls.

**Tech Stack:** Go, Chi router, following patterns from `internal/api/handlers/`

**Prerequisites:** Part 4 (service + tool) completed

---

## Task 1: Create Sandbox Handler

**Files:**
- Create: `internal/api/handlers/sandbox_handler.go`
- Test: `internal/api/handlers/sandbox_handler_test.go`

**Step 1: Write the failing test**

```go
// internal/api/handlers/sandbox_handler_test.go
package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/sandbox"
	"github.com/anthropics/agentic-platform/internal/service"
)

func TestSandboxHandler_GetSettings(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)
	handler := NewSandboxHandler(svc)

	r := chi.NewRouter()
	r.Get("/orgs/{orgID}/sandbox/settings", handler.GetSettings)

	req := httptest.NewRequest("GET", "/orgs/org-123/sandbox/settings", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status = %v, want %v", w.Code, http.StatusOK)
	}

	var settings domain.OrgSandboxSettings
	if err := json.NewDecoder(w.Body).Decode(&settings); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if settings.OrgID != "org-123" {
		t.Errorf("OrgID = %v, want org-123", settings.OrgID)
	}
	if settings.MemoryLimitMB != 512 {
		t.Errorf("MemoryLimitMB = %v, want 512", settings.MemoryLimitMB)
	}
}

func TestSandboxHandler_UpdateSettings(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)
	handler := NewSandboxHandler(svc)

	r := chi.NewRouter()
	r.Put("/orgs/{orgID}/sandbox/settings", handler.UpdateSettings)

	body := map[string]any{
		"memoryLimitMb":  1024,
		"cpuCores":       2.0,
		"timeoutSeconds": 120,
		"diskLimitMb":    200,
		"maxProcesses":   100,
	}
	bodyBytes, _ := json.Marshal(body)

	req := httptest.NewRequest("PUT", "/orgs/org-123/sandbox/settings", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status = %v, want %v, body: %s", w.Code, http.StatusOK, w.Body.String())
	}

	// Verify settings were updated
	settings, _ := svc.GetOrCreateSettings(req.Context(), "org-123")
	if settings.MemoryLimitMB != 1024 {
		t.Errorf("MemoryLimitMB = %v, want 1024", settings.MemoryLimitMB)
	}
}

func TestSandboxHandler_UpdateSettings_ValidationError(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)
	handler := NewSandboxHandler(svc)

	r := chi.NewRouter()
	r.Put("/orgs/{orgID}/sandbox/settings", handler.UpdateSettings)

	// Memory too high
	body := map[string]any{
		"memoryLimitMb": 10000, // Max is 4096
	}
	bodyBytes, _ := json.Marshal(body)

	req := httptest.NewRequest("PUT", "/orgs/org-123/sandbox/settings", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("status = %v, want %v", w.Code, http.StatusBadRequest)
	}
}

func TestSandboxHandler_GetExecutions(t *testing.T) {
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	svc := service.NewSandboxService(repo, runtime)
	handler := NewSandboxHandler(svc)

	// Create an execution
	exec := &domain.SandboxExecution{
		ID:        "exec-123",
		ProjectID: "proj-456",
		Runtime:   "python",
		Status:    domain.StatusCompleted,
	}
	repo.SaveExecution(nil, exec)

	r := chi.NewRouter()
	r.Get("/projects/{projectID}/sandbox/executions", handler.GetExecutions)

	req := httptest.NewRequest("GET", "/projects/proj-456/sandbox/executions", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("status = %v, want %v", w.Code, http.StatusOK)
	}

	var executions []*domain.SandboxExecution
	if err := json.NewDecoder(w.Body).Decode(&executions); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if len(executions) != 1 {
		t.Errorf("len(executions) = %v, want 1", len(executions))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -run TestSandboxHandler -v`
Expected: FAIL - undefined: NewSandboxHandler

**Step 3: Write the handler implementation**

```go
// internal/api/handlers/sandbox_handler.go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/service"
)

// SandboxHandler handles sandbox settings API requests.
type SandboxHandler struct {
	svc *service.SandboxService
}

// NewSandboxHandler creates a new sandbox handler.
func NewSandboxHandler(svc *service.SandboxService) *SandboxHandler {
	return &SandboxHandler{svc: svc}
}

// GetSettings returns sandbox settings for an organization.
func (h *SandboxHandler) GetSettings(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	if orgID == "" {
		http.Error(w, "orgID is required", http.StatusBadRequest)
		return
	}

	settings, err := h.svc.GetOrCreateSettings(r.Context(), orgID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(settings)
}

// UpdateSettings updates sandbox settings for an organization.
func (h *SandboxHandler) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	if orgID == "" {
		http.Error(w, "orgID is required", http.StatusBadRequest)
		return
	}

	// Get existing settings first
	settings, err := h.svc.GetOrCreateSettings(r.Context(), orgID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Decode partial update
	var update struct {
		DisabledTools   []string  `json:"disabledTools"`
		MemoryLimitMB   *int      `json:"memoryLimitMb"`
		CPUCores        *float64  `json:"cpuCores"`
		TimeoutSeconds  *int      `json:"timeoutSeconds"`
		DiskLimitMB     *int      `json:"diskLimitMb"`
		MaxProcesses    *int      `json:"maxProcesses"`
		EnabledRuntimes []string  `json:"enabledRuntimes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// Apply updates
	if update.DisabledTools != nil {
		settings.DisabledTools = update.DisabledTools
	}
	if update.MemoryLimitMB != nil {
		settings.MemoryLimitMB = *update.MemoryLimitMB
	}
	if update.CPUCores != nil {
		settings.CPUCores = *update.CPUCores
	}
	if update.TimeoutSeconds != nil {
		settings.TimeoutSeconds = *update.TimeoutSeconds
	}
	if update.DiskLimitMB != nil {
		settings.DiskLimitMB = *update.DiskLimitMB
	}
	if update.MaxProcesses != nil {
		settings.MaxProcesses = *update.MaxProcesses
	}
	if update.EnabledRuntimes != nil {
		settings.EnabledRuntimes = update.EnabledRuntimes
	}

	// Validate and save
	if err := h.svc.UpdateSettings(r.Context(), settings); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(settings)
}

// GetExecutions returns sandbox execution history for a project.
func (h *SandboxHandler) GetExecutions(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	if projectID == "" {
		http.Error(w, "projectID is required", http.StatusBadRequest)
		return
	}

	executions, err := h.svc.GetExecutionsByProject(r.Context(), projectID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(executions)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/api/handlers/... -run TestSandboxHandler -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/sandbox_handler.go internal/api/handlers/sandbox_handler_test.go
git commit -m "feat(api): add sandbox settings HTTP handlers"
```

---

## Task 2: Register Sandbox Routes

**Files:**
- Modify: `internal/api/routes/routes.go`

**Step 1: Read current routes file**

Read `internal/api/routes/routes.go` to understand the routing pattern.

**Step 2: Add sandbox routes**

```go
// Add to routes.go

// Sandbox settings (Admin only)
r.Route("/orgs/{orgID}/sandbox", func(r chi.Router) {
	// TODO: Add RequireOrgRole(OrgRoleAdmin) middleware
	r.Get("/settings", sandboxHandler.GetSettings)
	r.Put("/settings", sandboxHandler.UpdateSettings)
})

// Sandbox execution history (per project)
r.Get("/projects/{projectID}/sandbox/executions", sandboxHandler.GetExecutions)
```

**Step 3: Verify routes compile**

Run: `go build ./internal/api/...`
Expected: Success

**Step 4: Commit**

```bash
git add internal/api/routes/routes.go
git commit -m "feat(api): add sandbox routes to router"
```

---

## Task 3: Wire Sandbox into Agent Executor

**Files:**
- Modify: `internal/agents/executor.go`

**Step 1: Read current executor**

Read `internal/agents/executor.go` to find `executeToolCallStep`.

**Step 2: Update executor to set context values**

The executor should set org/project/task context values before tool execution:

```go
// In executeToolCallStep method
func (e *Executor) executeToolCallStep(ctx context.Context, step *Step, stepCtx *StepContext) error {
	toolName := step.ToolCall.Name
	args := step.ToolCall.Arguments

	// Add context values for tools (e.g., sandbox)
	ctx = context.WithValue(ctx, "orgId", stepCtx.OrgID)
	ctx = context.WithValue(ctx, "projectId", stepCtx.ProjectID)
	ctx = context.WithValue(ctx, "taskId", stepCtx.TaskID)

	result, err := e.toolRegistry.Execute(ctx, toolName, args)
	if err != nil {
		return &AgentError{
			Code:    "tool_execution_failed",
			Message: err.Error(),
			Details: map[string]any{"tool": toolName},
		}
	}

	stepCtx.ToolResults[toolName] = result
	return nil
}
```

**Step 3: Run executor tests**

Run: `go test ./internal/agents/... -v`
Expected: PASS

**Step 4: Commit**

```bash
git add internal/agents/executor.go
git commit -m "feat(agents): wire sandbox context into executor tool calls"
```

---

## Task 4: Add Integration Test

**Files:**
- Create or modify: `internal/agents/executor_test.go`

**Step 1: Write integration test**

```go
// Add to internal/agents/executor_test.go
func TestExecutor_SandboxToolExecution(t *testing.T) {
	// Setup
	repo := memory.NewSandboxRepository()
	runtime := sandbox.NewDockerRuntime(sandbox.WithMockMode(true))
	sandboxSvc := service.NewSandboxService(repo, runtime)

	registry := tools.NewRegistry()
	registry.Register(tools.NewExecuteInSandboxTool(sandboxSvc))

	executor := NewExecutor(WithToolRegistry(registry))

	ctx := context.Background()
	stepCtx := &StepContext{
		OrgID:       "org-123",
		ProjectID:   "proj-456",
		TaskID:      "task-789",
		ToolResults: make(map[string]any),
	}

	// Simulate tool call step
	step := &Step{
		Type: StepToolCall,
		ToolCall: &ToolCall{
			Name: "execute_in_sandbox",
			Arguments: map[string]any{
				"runtime": "python",
				"command": []any{"python", "-c", "print('hello')"},
			},
		},
	}

	err := executor.executeToolCallStep(ctx, step, stepCtx)
	if err != nil {
		t.Fatalf("executeToolCallStep() error = %v", err)
	}

	// Verify result
	result := stepCtx.ToolResults["execute_in_sandbox"]
	if result == nil {
		t.Fatal("expected sandbox result")
	}

	execResult, ok := result.(*domain.SandboxExecution)
	if !ok {
		t.Fatalf("result type = %T, want *domain.SandboxExecution", result)
	}
	if execResult.Status != domain.StatusCompleted {
		t.Errorf("Status = %v, want completed", execResult.Status)
	}
}
```

**Step 2: Run test**

Run: `go test ./internal/agents/... -run TestExecutor_SandboxToolExecution -v`
Expected: PASS

**Step 3: Commit**

```bash
git add internal/agents/executor_test.go
git commit -m "test(agents): add sandbox tool execution integration test"
```

---

## Task 5: Verify All Tests Pass

**Step 1: Run all tests**

Run: `go test ./... -v`
Expected: All PASS

**Step 2: Run linter**

Run: `go vet ./...`
Expected: No errors

**Step 3: Build**

Run: `go build ./...`
Expected: Success

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat(api): complete sandbox API integration"
```

---

## Summary

After completing Part 5, you will have:

**Created Files:**
- `internal/api/handlers/sandbox_handler.go` - HTTP handlers
- `internal/api/handlers/sandbox_handler_test.go` - Handler tests

**Modified Files:**
- `internal/api/routes/routes.go` - Added routes
- `internal/agents/executor.go` - Context propagation

**API Endpoints:**
- `GET /orgs/{orgID}/sandbox/settings` - Get sandbox settings
- `PUT /orgs/{orgID}/sandbox/settings` - Update sandbox settings
- `GET /projects/{projectID}/sandbox/executions` - Get execution history

**Next:** Proceed to [06-resource-monitoring.md](./06-resource-monitoring.md)
