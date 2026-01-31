# Repository Layer (Tasks 6-9)

> Back to [Overview](./00-overview.md)

---

## Task 6: Workflow Repository Interface

**Files:**
- Create: `internal/repository/workflow_repository.go`

**Step 1: Create repository interface**

Create `internal/repository/workflow_repository.go`:
```go
package repository

import (
	"context"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// WorkflowRepository defines the interface for workflow storage
type WorkflowRepository interface {
	// Workflow operations
	CreateWorkflow(ctx context.Context, w *domain.Workflow) error
	GetWorkflow(ctx context.Context, id string) (*domain.Workflow, error)
	GetWorkflowByProject(ctx context.Context, projectID string) (*domain.Workflow, error)
	ListWorkflows(ctx context.Context, orgID string) ([]*domain.Workflow, error)
	UpdateWorkflow(ctx context.Context, w *domain.Workflow) error

	// Escalation operations
	CreateEscalation(ctx context.Context, e *domain.Escalation) error
	GetEscalation(ctx context.Context, id string) (*domain.Escalation, error)
	ListEscalationsByWorkflow(ctx context.Context, workflowID string) ([]*domain.Escalation, error)
	ListPendingEscalations(ctx context.Context, orgID string) ([]*domain.Escalation, error)
	UpdateEscalation(ctx context.Context, e *domain.Escalation) error

	// Event operations (event sourcing)
	AppendEvent(ctx context.Context, e *domain.Event) error
	ListEventsByWorkflow(ctx context.Context, workflowID string) ([]*domain.Event, error)
	ListEventsSince(ctx context.Context, workflowID string, since int64) ([]*domain.Event, error)
}
```

**Step 2: Verify it compiles**

Run: `go build ./...`

Expected: Success

**Step 3: Commit**

```bash
git add internal/repository/workflow_repository.go
git commit -m "feat: add WorkflowRepository interface"
```

---

## Task 7: In-Memory Workflow Repository - Core Operations

**Files:**
- Create: `internal/repository/memory/workflow_repository.go`
- Create: `internal/repository/memory/workflow_repository_test.go`

**Step 1: Write the failing test**

Create `internal/repository/memory/workflow_repository_test.go`:
```go
package memory

import (
	"context"
	"testing"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

func TestWorkflowRepository_CreateAndGet(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	wf := &domain.Workflow{
		ID:           "wf-123",
		ProjectID:    "proj-456",
		OrgID:        "org-789",
		Status:       domain.StatusDraft,
		CurrentPhase: domain.PhaseRequirements,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	err := repo.CreateWorkflow(ctx, wf)
	if err != nil {
		t.Fatalf("CreateWorkflow() error = %v", err)
	}

	got, err := repo.GetWorkflow(ctx, "wf-123")
	if err != nil {
		t.Fatalf("GetWorkflow() error = %v", err)
	}

	if got.ID != wf.ID {
		t.Errorf("GetWorkflow() ID = %v, want %v", got.ID, wf.ID)
	}
	if got.ProjectID != wf.ProjectID {
		t.Errorf("GetWorkflow() ProjectID = %v, want %v", got.ProjectID, wf.ProjectID)
	}
}

func TestWorkflowRepository_GetNotFound(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	_, err := repo.GetWorkflow(ctx, "nonexistent")
	if err != repository.ErrNotFound {
		t.Errorf("GetWorkflow() error = %v, want %v", err, repository.ErrNotFound)
	}
}

func TestWorkflowRepository_GetByProject(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	wf := &domain.Workflow{
		ID:           "wf-123",
		ProjectID:    "proj-456",
		OrgID:        "org-789",
		Status:       domain.StatusDraft,
		CurrentPhase: domain.PhaseRequirements,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	_ = repo.CreateWorkflow(ctx, wf)

	got, err := repo.GetWorkflowByProject(ctx, "proj-456")
	if err != nil {
		t.Fatalf("GetWorkflowByProject() error = %v", err)
	}

	if got.ID != wf.ID {
		t.Errorf("GetWorkflowByProject() ID = %v, want %v", got.ID, wf.ID)
	}
}

func TestWorkflowRepository_ListByOrg(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	wf1 := &domain.Workflow{
		ID:           "wf-1",
		ProjectID:    "proj-1",
		OrgID:        "org-A",
		Status:       domain.StatusDraft,
		CurrentPhase: domain.PhaseRequirements,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	wf2 := &domain.Workflow{
		ID:           "wf-2",
		ProjectID:    "proj-2",
		OrgID:        "org-A",
		Status:       domain.StatusInProgress,
		CurrentPhase: domain.PhaseArchitecture,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	wf3 := &domain.Workflow{
		ID:           "wf-3",
		ProjectID:    "proj-3",
		OrgID:        "org-B",
		Status:       domain.StatusDraft,
		CurrentPhase: domain.PhaseRequirements,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	_ = repo.CreateWorkflow(ctx, wf1)
	_ = repo.CreateWorkflow(ctx, wf2)
	_ = repo.CreateWorkflow(ctx, wf3)

	workflows, err := repo.ListWorkflows(ctx, "org-A")
	if err != nil {
		t.Fatalf("ListWorkflows() error = %v", err)
	}

	if len(workflows) != 2 {
		t.Errorf("ListWorkflows() count = %d, want 2", len(workflows))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository`

Expected: FAIL with "undefined: NewWorkflowRepository"

**Step 3: Write in-memory implementation**

Create `internal/repository/memory/workflow_repository.go`:
```go
package memory

import (
	"context"
	"sync"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// WorkflowRepository is an in-memory implementation of repository.WorkflowRepository
type WorkflowRepository struct {
	mu          sync.RWMutex
	workflows   map[string]*domain.Workflow
	escalations map[string]*domain.Escalation
	events      map[string][]*domain.Event // workflowID -> events
}

// NewWorkflowRepository creates a new in-memory workflow repository
func NewWorkflowRepository() *WorkflowRepository {
	return &WorkflowRepository{
		workflows:   make(map[string]*domain.Workflow),
		escalations: make(map[string]*domain.Escalation),
		events:      make(map[string][]*domain.Event),
	}
}

func (r *WorkflowRepository) CreateWorkflow(ctx context.Context, w *domain.Workflow) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.workflows[w.ID]; exists {
		return repository.ErrAlreadyExists
	}

	// Store a copy
	copy := *w
	r.workflows[w.ID] = &copy
	return nil
}

func (r *WorkflowRepository) GetWorkflow(ctx context.Context, id string) (*domain.Workflow, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	wf, exists := r.workflows[id]
	if !exists {
		return nil, repository.ErrNotFound
	}

	// Return a copy
	copy := *wf
	return &copy, nil
}

func (r *WorkflowRepository) GetWorkflowByProject(ctx context.Context, projectID string) (*domain.Workflow, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, wf := range r.workflows {
		if wf.ProjectID == projectID {
			copy := *wf
			return &copy, nil
		}
	}

	return nil, repository.ErrNotFound
}

func (r *WorkflowRepository) ListWorkflows(ctx context.Context, orgID string) ([]*domain.Workflow, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Workflow
	for _, wf := range r.workflows {
		if wf.OrgID == orgID {
			copy := *wf
			result = append(result, &copy)
		}
	}

	return result, nil
}

func (r *WorkflowRepository) UpdateWorkflow(ctx context.Context, w *domain.Workflow) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.workflows[w.ID]; !exists {
		return repository.ErrNotFound
	}

	copy := *w
	r.workflows[w.ID] = &copy
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/workflow_repository.go internal/repository/memory/workflow_repository_test.go
git commit -m "feat: add in-memory WorkflowRepository core operations"
```

---

## Task 8: In-Memory Workflow Repository - Escalation Operations

**Files:**
- Modify: `internal/repository/memory/workflow_repository.go`
- Modify: `internal/repository/memory/workflow_repository_test.go`

**Step 1: Write the failing test**

Add to `internal/repository/memory/workflow_repository_test.go`:
```go
func TestWorkflowRepository_Escalations(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	// Create a workflow first
	wf := &domain.Workflow{
		ID:           "wf-123",
		ProjectID:    "proj-456",
		OrgID:        "org-789",
		Status:       domain.StatusBlocked,
		CurrentPhase: domain.PhaseRequirements,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	_ = repo.CreateWorkflow(ctx, wf)

	// Create escalation
	esc := &domain.Escalation{
		ID:           "esc-123",
		WorkflowID:   "wf-123",
		ArtifactID:   "art-456",
		ConstraintID: "con-789",
		Status:       domain.EscalationPending,
		CreatedAt:    time.Now(),
	}

	err := repo.CreateEscalation(ctx, esc)
	if err != nil {
		t.Fatalf("CreateEscalation() error = %v", err)
	}

	got, err := repo.GetEscalation(ctx, "esc-123")
	if err != nil {
		t.Fatalf("GetEscalation() error = %v", err)
	}

	if got.ID != esc.ID {
		t.Errorf("GetEscalation() ID = %v, want %v", got.ID, esc.ID)
	}
}

func TestWorkflowRepository_ListEscalationsByWorkflow(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	esc1 := &domain.Escalation{
		ID:           "esc-1",
		WorkflowID:   "wf-123",
		ArtifactID:   "art-1",
		ConstraintID: "con-1",
		Status:       domain.EscalationPending,
		CreatedAt:    time.Now(),
	}
	esc2 := &domain.Escalation{
		ID:           "esc-2",
		WorkflowID:   "wf-123",
		ArtifactID:   "art-2",
		ConstraintID: "con-2",
		Status:       domain.EscalationPending,
		CreatedAt:    time.Now(),
	}
	esc3 := &domain.Escalation{
		ID:           "esc-3",
		WorkflowID:   "wf-other",
		ArtifactID:   "art-3",
		ConstraintID: "con-3",
		Status:       domain.EscalationPending,
		CreatedAt:    time.Now(),
	}

	_ = repo.CreateEscalation(ctx, esc1)
	_ = repo.CreateEscalation(ctx, esc2)
	_ = repo.CreateEscalation(ctx, esc3)

	escalations, err := repo.ListEscalationsByWorkflow(ctx, "wf-123")
	if err != nil {
		t.Fatalf("ListEscalationsByWorkflow() error = %v", err)
	}

	if len(escalations) != 2 {
		t.Errorf("ListEscalationsByWorkflow() count = %d, want 2", len(escalations))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository_Escalation`

Expected: FAIL with "CreateEscalation not defined"

**Step 3: Add escalation methods**

Add to `internal/repository/memory/workflow_repository.go`:
```go
func (r *WorkflowRepository) CreateEscalation(ctx context.Context, e *domain.Escalation) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.escalations[e.ID]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *e
	r.escalations[e.ID] = &copy
	return nil
}

func (r *WorkflowRepository) GetEscalation(ctx context.Context, id string) (*domain.Escalation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	esc, exists := r.escalations[id]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *esc
	return &copy, nil
}

func (r *WorkflowRepository) ListEscalationsByWorkflow(ctx context.Context, workflowID string) ([]*domain.Escalation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Escalation
	for _, esc := range r.escalations {
		if esc.WorkflowID == workflowID {
			copy := *esc
			result = append(result, &copy)
		}
	}

	return result, nil
}

func (r *WorkflowRepository) ListPendingEscalations(ctx context.Context, orgID string) ([]*domain.Escalation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	// First get all workflows for the org
	orgWorkflows := make(map[string]bool)
	for _, wf := range r.workflows {
		if wf.OrgID == orgID {
			orgWorkflows[wf.ID] = true
		}
	}

	var result []*domain.Escalation
	for _, esc := range r.escalations {
		if orgWorkflows[esc.WorkflowID] && esc.Status == domain.EscalationPending {
			copy := *esc
			result = append(result, &copy)
		}
	}

	return result, nil
}

func (r *WorkflowRepository) UpdateEscalation(ctx context.Context, e *domain.Escalation) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.escalations[e.ID]; !exists {
		return repository.ErrNotFound
	}

	copy := *e
	r.escalations[e.ID] = &copy
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository_Escalation`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/workflow_repository.go internal/repository/memory/workflow_repository_test.go
git commit -m "feat: add escalation operations to WorkflowRepository"
```

---

## Task 9: In-Memory Workflow Repository - Event Operations

**Files:**
- Modify: `internal/repository/memory/workflow_repository.go`
- Modify: `internal/repository/memory/workflow_repository_test.go`

**Step 1: Write the failing test**

Add to `internal/repository/memory/workflow_repository_test.go`:
```go
func TestWorkflowRepository_Events(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	evt1 := &domain.Event{
		ID:         "evt-1",
		WorkflowID: "wf-123",
		Type:       domain.EventWorkflowCreated,
		ActorType:  "user",
		ActorID:    "user-456",
		Timestamp:  time.Now(),
	}
	evt2 := &domain.Event{
		ID:         "evt-2",
		WorkflowID: "wf-123",
		Type:       domain.EventPhaseStarted,
		ActorType:  "agent",
		ActorID:    "agent-req",
		Data:       map[string]any{"phase": "requirements"},
		Timestamp:  time.Now().Add(time.Second),
	}

	err := repo.AppendEvent(ctx, evt1)
	if err != nil {
		t.Fatalf("AppendEvent() error = %v", err)
	}

	err = repo.AppendEvent(ctx, evt2)
	if err != nil {
		t.Fatalf("AppendEvent() error = %v", err)
	}

	events, err := repo.ListEventsByWorkflow(ctx, "wf-123")
	if err != nil {
		t.Fatalf("ListEventsByWorkflow() error = %v", err)
	}

	if len(events) != 2 {
		t.Errorf("ListEventsByWorkflow() count = %d, want 2", len(events))
	}
}

func TestWorkflowRepository_ListEventsSince(t *testing.T) {
	repo := NewWorkflowRepository()
	ctx := context.Background()

	baseTime := time.Now()

	evt1 := &domain.Event{
		ID:         "evt-1",
		WorkflowID: "wf-123",
		Type:       domain.EventWorkflowCreated,
		ActorType:  "user",
		ActorID:    "user-456",
		Timestamp:  baseTime,
	}
	evt2 := &domain.Event{
		ID:         "evt-2",
		WorkflowID: "wf-123",
		Type:       domain.EventPhaseStarted,
		ActorType:  "agent",
		ActorID:    "agent-req",
		Timestamp:  baseTime.Add(time.Hour),
	}

	_ = repo.AppendEvent(ctx, evt1)
	_ = repo.AppendEvent(ctx, evt2)

	// Get events since after the first event
	since := baseTime.Add(time.Minute).UnixNano()
	events, err := repo.ListEventsSince(ctx, "wf-123", since)
	if err != nil {
		t.Fatalf("ListEventsSince() error = %v", err)
	}

	if len(events) != 1 {
		t.Errorf("ListEventsSince() count = %d, want 1", len(events))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository_Event`

Expected: FAIL with "AppendEvent not defined"

**Step 3: Add event methods**

Add to `internal/repository/memory/workflow_repository.go`:
```go
func (r *WorkflowRepository) AppendEvent(ctx context.Context, e *domain.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	copy := *e
	r.events[e.WorkflowID] = append(r.events[e.WorkflowID], &copy)
	return nil
}

func (r *WorkflowRepository) ListEventsByWorkflow(ctx context.Context, workflowID string) ([]*domain.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	events := r.events[workflowID]
	result := make([]*domain.Event, len(events))
	for i, e := range events {
		copy := *e
		result[i] = &copy
	}

	return result, nil
}

func (r *WorkflowRepository) ListEventsSince(ctx context.Context, workflowID string, since int64) ([]*domain.Event, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Event
	for _, e := range r.events[workflowID] {
		if e.Timestamp.UnixNano() > since {
			copy := *e
			result = append(result, &copy)
		}
	}

	return result, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/repository/memory/... -run TestWorkflowRepository_Event`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/workflow_repository.go internal/repository/memory/workflow_repository_test.go
git commit -m "feat: add event sourcing operations to WorkflowRepository"
```
