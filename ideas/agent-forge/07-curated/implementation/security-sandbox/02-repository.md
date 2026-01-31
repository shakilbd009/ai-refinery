# Part 2: Sandbox Repository

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create repository interface and in-memory implementation for sandbox settings and execution logs.

**Architecture:** Follow existing repository patterns in `internal/repository/` - interface abstraction, memory implementation with mutex-protected maps, copy-on-read/write.

**Tech Stack:** Go, following patterns from `internal/repository/permissions_repository.go`

**Prerequisites:** Part 1 (data models) completed

---

## Task 1: Create Repository Interface

**Files:**
- Create: `internal/repository/sandbox_repository.go`

**Step 1: Write the interface**

```go
// internal/repository/sandbox_repository.go
package repository

import (
	"context"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// SandboxRepository provides access to sandbox settings and execution logs.
type SandboxRepository interface {
	// Settings management
	GetSettings(ctx context.Context, orgID string) (*domain.OrgSandboxSettings, error)
	SaveSettings(ctx context.Context, settings *domain.OrgSandboxSettings) error

	// Execution logging
	GetExecution(ctx context.Context, id string) (*domain.SandboxExecution, error)
	SaveExecution(ctx context.Context, exec *domain.SandboxExecution) error
	ListExecutionsByProject(ctx context.Context, projectID string) ([]*domain.SandboxExecution, error)
	ListExecutionsByTask(ctx context.Context, taskID string) ([]*domain.SandboxExecution, error)
}
```

**Step 2: Verify it compiles**

Run: `go build ./internal/repository/...`
Expected: Success (no output)

**Step 3: Commit**

```bash
git add internal/repository/sandbox_repository.go
git commit -m "feat(repository): add SandboxRepository interface"
```

---

## Task 2: Create Memory Repository - Settings Methods

**Files:**
- Create: `internal/repository/memory/sandbox_repository.go`
- Test: `internal/repository/memory/sandbox_repository_test.go`

**Step 1: Write the failing test for settings**

```go
// internal/repository/memory/sandbox_repository_test.go
package memory

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
)

func TestMemorySandboxRepository_Settings(t *testing.T) {
	repo := NewSandboxRepository()
	ctx := context.Background()

	// Create settings
	settings := domain.NewDefaultOrgSandboxSettings("org-123")
	err := repo.SaveSettings(ctx, settings)
	if err != nil {
		t.Fatalf("SaveSettings() error = %v", err)
	}

	// Get settings
	got, err := repo.GetSettings(ctx, "org-123")
	if err != nil {
		t.Fatalf("GetSettings() error = %v", err)
	}
	if got.OrgID != "org-123" {
		t.Errorf("OrgID = %v, want org-123", got.OrgID)
	}
	if got.MemoryLimitMB != 512 {
		t.Errorf("MemoryLimitMB = %v, want 512", got.MemoryLimitMB)
	}

	// Get non-existent settings returns nil
	got, err = repo.GetSettings(ctx, "org-nonexistent")
	if err != nil {
		t.Fatalf("GetSettings() error = %v", err)
	}
	if got != nil {
		t.Errorf("expected nil for non-existent org, got %v", got)
	}

	// Verify copy-on-read (mutation doesn't affect stored)
	got, _ = repo.GetSettings(ctx, "org-123")
	got.MemoryLimitMB = 9999
	got2, _ := repo.GetSettings(ctx, "org-123")
	if got2.MemoryLimitMB != 512 {
		t.Errorf("copy-on-read failed: MemoryLimitMB = %v, want 512", got2.MemoryLimitMB)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestMemorySandboxRepository_Settings -v`
Expected: FAIL - undefined: NewSandboxRepository

**Step 3: Write minimal implementation**

```go
// internal/repository/memory/sandbox_repository.go
package memory

import (
	"context"
	"sync"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// SandboxRepository is an in-memory implementation of repository.SandboxRepository.
type SandboxRepository struct {
	mu         sync.RWMutex
	settings   map[string]*domain.OrgSandboxSettings // orgID -> settings
	executions map[string]*domain.SandboxExecution   // execID -> execution
}

// NewSandboxRepository creates a new in-memory sandbox repository.
func NewSandboxRepository() *SandboxRepository {
	return &SandboxRepository{
		settings:   make(map[string]*domain.OrgSandboxSettings),
		executions: make(map[string]*domain.SandboxExecution),
	}
}

func (r *SandboxRepository) GetSettings(ctx context.Context, orgID string) (*domain.OrgSandboxSettings, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	settings, ok := r.settings[orgID]
	if !ok {
		return nil, nil
	}
	// Return a copy
	copy := *settings
	if settings.DisabledTools != nil {
		copy.DisabledTools = make([]string, len(settings.DisabledTools))
		for i, t := range settings.DisabledTools {
			copy.DisabledTools[i] = t
		}
	}
	if settings.EnabledRuntimes != nil {
		copy.EnabledRuntimes = make([]string, len(settings.EnabledRuntimes))
		for i, r := range settings.EnabledRuntimes {
			copy.EnabledRuntimes[i] = r
		}
	}
	return &copy, nil
}

func (r *SandboxRepository) SaveSettings(ctx context.Context, settings *domain.OrgSandboxSettings) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := *settings
	if settings.DisabledTools != nil {
		copy.DisabledTools = make([]string, len(settings.DisabledTools))
		for i, t := range settings.DisabledTools {
			copy.DisabledTools[i] = t
		}
	}
	if settings.EnabledRuntimes != nil {
		copy.EnabledRuntimes = make([]string, len(settings.EnabledRuntimes))
		for i, rt := range settings.EnabledRuntimes {
			copy.EnabledRuntimes[i] = rt
		}
	}
	r.settings[settings.OrgID] = &copy
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/repository/memory/... -run TestMemorySandboxRepository_Settings -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/sandbox_repository.go internal/repository/memory/sandbox_repository_test.go
git commit -m "feat(repository): add memory SandboxRepository settings methods"
```

---

## Task 3: Add Execution Methods to Memory Repository

**Files:**
- Modify: `internal/repository/memory/sandbox_repository.go`
- Modify: `internal/repository/memory/sandbox_repository_test.go`

**Step 1: Write the failing test for executions**

```go
// Add to internal/repository/memory/sandbox_repository_test.go
import "time"

func TestMemorySandboxRepository_Executions(t *testing.T) {
	repo := NewSandboxRepository()
	ctx := context.Background()

	// Create execution
	exec := &domain.SandboxExecution{
		ID:          "exec-123",
		ProjectID:   "proj-456",
		AgentTaskID: "task-789",
		Runtime:     "python",
		Command:     "python test.py",
		Status:      domain.StatusCompleted,
		StartedAt:   time.Now(),
		EndedAt:     time.Now(),
	}
	err := repo.SaveExecution(ctx, exec)
	if err != nil {
		t.Fatalf("SaveExecution() error = %v", err)
	}

	// Get execution
	got, err := repo.GetExecution(ctx, "exec-123")
	if err != nil {
		t.Fatalf("GetExecution() error = %v", err)
	}
	if got.ID != "exec-123" {
		t.Errorf("ID = %v, want exec-123", got.ID)
	}
	if got.Runtime != "python" {
		t.Errorf("Runtime = %v, want python", got.Runtime)
	}

	// Get non-existent returns nil
	got, err = repo.GetExecution(ctx, "nonexistent")
	if err != nil {
		t.Fatalf("GetExecution() error = %v", err)
	}
	if got != nil {
		t.Errorf("expected nil for non-existent, got %v", got)
	}

	// List executions by project
	execs, err := repo.ListExecutionsByProject(ctx, "proj-456")
	if err != nil {
		t.Fatalf("ListExecutionsByProject() error = %v", err)
	}
	if len(execs) != 1 {
		t.Errorf("len(execs) = %v, want 1", len(execs))
	}

	// List by different project returns empty
	execs, err = repo.ListExecutionsByProject(ctx, "other-proj")
	if err != nil {
		t.Fatalf("ListExecutionsByProject() error = %v", err)
	}
	if len(execs) != 0 {
		t.Errorf("len(execs) = %v, want 0", len(execs))
	}
}

func TestMemorySandboxRepository_ListByTask(t *testing.T) {
	repo := NewSandboxRepository()
	ctx := context.Background()

	// Create two executions for same task
	exec1 := &domain.SandboxExecution{
		ID:          "exec-1",
		ProjectID:   "proj-1",
		AgentTaskID: "task-1",
		Status:      domain.StatusCompleted,
	}
	exec2 := &domain.SandboxExecution{
		ID:          "exec-2",
		ProjectID:   "proj-1",
		AgentTaskID: "task-1",
		Status:      domain.StatusTimeout,
	}
	repo.SaveExecution(ctx, exec1)
	repo.SaveExecution(ctx, exec2)

	execs, err := repo.ListExecutionsByTask(ctx, "task-1")
	if err != nil {
		t.Fatalf("ListExecutionsByTask() error = %v", err)
	}
	if len(execs) != 2 {
		t.Errorf("len(execs) = %v, want 2", len(execs))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestMemorySandboxRepository_Executions -v`
Expected: FAIL - r.GetExecution undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/repository/memory/sandbox_repository.go

func (r *SandboxRepository) GetExecution(ctx context.Context, id string) (*domain.SandboxExecution, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	exec, ok := r.executions[id]
	if !ok {
		return nil, nil
	}
	copy := *exec
	return &copy, nil
}

func (r *SandboxRepository) SaveExecution(ctx context.Context, exec *domain.SandboxExecution) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := *exec
	r.executions[exec.ID] = &copy
	return nil
}

func (r *SandboxRepository) ListExecutionsByProject(ctx context.Context, projectID string) ([]*domain.SandboxExecution, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.SandboxExecution
	for _, exec := range r.executions {
		if exec.ProjectID == projectID {
			copy := *exec
			result = append(result, &copy)
		}
	}
	return result, nil
}

func (r *SandboxRepository) ListExecutionsByTask(ctx context.Context, taskID string) ([]*domain.SandboxExecution, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.SandboxExecution
	for _, exec := range r.executions {
		if exec.AgentTaskID == taskID {
			copy := *exec
			result = append(result, &copy)
		}
	}
	return result, nil
}
```

**Step 4: Run all tests**

Run: `go test ./internal/repository/memory/... -run TestMemorySandboxRepository -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/sandbox_repository.go internal/repository/memory/sandbox_repository_test.go
git commit -m "feat(repository): add execution methods to memory SandboxRepository"
```

---

## Task 4: Verify Interface Compliance

**Step 1: Add compile-time interface check**

```go
// Add to internal/repository/memory/sandbox_repository.go at package level
import "github.com/anthropics/agentic-platform/internal/repository"

var _ repository.SandboxRepository = (*SandboxRepository)(nil)
```

**Step 2: Run build**

Run: `go build ./internal/repository/...`
Expected: Success

**Step 3: Run all repository tests**

Run: `go test ./internal/repository/... -v`
Expected: All PASS

**Step 4: Commit**

```bash
git add internal/repository/memory/sandbox_repository.go
git commit -m "feat(repository): verify SandboxRepository interface compliance"
```

---

## Summary

After completing Part 2, you will have:

**Created Files:**
- `internal/repository/sandbox_repository.go` - Interface definition
- `internal/repository/memory/sandbox_repository.go` - Memory implementation
- `internal/repository/memory/sandbox_repository_test.go` - Test coverage

**Methods Implemented:**
- `GetSettings` / `SaveSettings` - Org sandbox configuration
- `GetExecution` / `SaveExecution` - Execution logging
- `ListExecutionsByProject` / `ListExecutionsByTask` - Query methods

**Next:** Proceed to [03-container-runtime.md](./03-container-runtime.md)
