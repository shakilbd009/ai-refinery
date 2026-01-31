# Service Layer (Tasks 10-13)

> Back to [Overview](./00-overview.md)

---

## Task 10: Workflow Service - Create Workflow

**Files:**
- Create: `internal/service/workflow_service.go`
- Create: `internal/service/workflow_service_test.go`

**Step 1: Write the failing test**

Create `internal/service/workflow_service_test.go`:
```go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func TestWorkflowService_CreateWorkflow(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	input := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}

	wf, err := svc.CreateWorkflow(ctx, input)
	if err != nil {
		t.Fatalf("CreateWorkflow() error = %v", err)
	}

	if wf.ID == "" {
		t.Error("CreateWorkflow() ID should not be empty")
	}
	if wf.ProjectID != input.ProjectID {
		t.Errorf("CreateWorkflow() ProjectID = %v, want %v", wf.ProjectID, input.ProjectID)
	}
	if wf.Status != domain.StatusDraft {
		t.Errorf("CreateWorkflow() Status = %v, want %v", wf.Status, domain.StatusDraft)
	}
	if wf.CurrentPhase != domain.PhaseRequirements {
		t.Errorf("CreateWorkflow() CurrentPhase = %v, want %v", wf.CurrentPhase, domain.PhaseRequirements)
	}
	if len(wf.Phases) != 4 {
		t.Errorf("CreateWorkflow() should initialize 4 phases, got %d", len(wf.Phases))
	}
}

func TestWorkflowService_CreateWorkflow_MissingProjectID(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	input := CreateWorkflowInput{
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}

	_, err := svc.CreateWorkflow(ctx, input)
	if err == nil {
		t.Error("CreateWorkflow() should fail with missing ProjectID")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/service/... -run TestWorkflowService_CreateWorkflow`

Expected: FAIL with "undefined: NewWorkflowService"

**Step 3: Write workflow service**

Create `internal/service/workflow_service.go`:
```go
package service

import (
	"context"
	"errors"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// WorkflowService handles business logic for workflows
type WorkflowService struct {
	repo repository.WorkflowRepository
}

// NewWorkflowService creates a new service instance
func NewWorkflowService(repo repository.WorkflowRepository) *WorkflowService {
	return &WorkflowService{repo: repo}
}

// CreateWorkflowInput contains the data needed to create a workflow
type CreateWorkflowInput struct {
	ProjectID string
	OrgID     string
	CreatedBy string
}

// CreateWorkflow creates a new workflow for a project
func (s *WorkflowService) CreateWorkflow(ctx context.Context, input CreateWorkflowInput) (*domain.Workflow, error) {
	if input.ProjectID == "" {
		return nil, errors.New("projectId is required")
	}
	if input.OrgID == "" {
		return nil, errors.New("orgId is required")
	}

	now := time.Now()

	// Initialize all four phases
	phases := []domain.PhaseState{
		{Phase: domain.PhaseRequirements, Status: domain.PhaseStatusPending},
		{Phase: domain.PhaseArchitecture, Status: domain.PhaseStatusPending},
		{Phase: domain.PhaseCode, Status: domain.PhaseStatusPending},
		{Phase: domain.PhaseSecurityReview, Status: domain.PhaseStatusPending},
	}

	wf := &domain.Workflow{
		ID:           generateID(),
		ProjectID:    input.ProjectID,
		OrgID:        input.OrgID,
		Status:       domain.StatusDraft,
		CurrentPhase: domain.PhaseRequirements,
		Phases:       phases,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err := wf.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateWorkflow(ctx, wf); err != nil {
		return nil, err
	}

	// Record creation event
	event := &domain.Event{
		ID:         generateID(),
		WorkflowID: wf.ID,
		Type:       domain.EventWorkflowCreated,
		ActorType:  "user",
		ActorID:    input.CreatedBy,
		Data: map[string]any{
			"projectId": input.ProjectID,
			"orgId":     input.OrgID,
		},
		Timestamp: now,
	}
	_ = s.repo.AppendEvent(ctx, event)

	return wf, nil
}

// GetWorkflow retrieves a workflow by ID
func (s *WorkflowService) GetWorkflow(ctx context.Context, id string) (*domain.Workflow, error) {
	return s.repo.GetWorkflow(ctx, id)
}

// GetWorkflowByProject retrieves a workflow by project ID
func (s *WorkflowService) GetWorkflowByProject(ctx context.Context, projectID string) (*domain.Workflow, error) {
	return s.repo.GetWorkflowByProject(ctx, projectID)
}

// ListWorkflows retrieves all workflows for an organization
func (s *WorkflowService) ListWorkflows(ctx context.Context, orgID string) ([]*domain.Workflow, error) {
	return s.repo.ListWorkflows(ctx, orgID)
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/service/... -run TestWorkflowService_CreateWorkflow`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/workflow_service.go internal/service/workflow_service_test.go
git commit -m "feat: add WorkflowService with CreateWorkflow"
```

---

## Task 11: Workflow Service - Start Workflow

**Files:**
- Modify: `internal/service/workflow_service.go`
- Modify: `internal/service/workflow_service_test.go`

**Step 1: Write the failing test**

Add to `internal/service/workflow_service_test.go`:
```go
func TestWorkflowService_StartWorkflow(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	// Create a workflow first
	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)

	// Start the workflow
	started, err := svc.StartWorkflow(ctx, wf.ID, "user-789")
	if err != nil {
		t.Fatalf("StartWorkflow() error = %v", err)
	}

	if started.Status != domain.StatusInProgress {
		t.Errorf("StartWorkflow() Status = %v, want %v", started.Status, domain.StatusInProgress)
	}
	if started.Phases[0].Status != domain.PhaseStatusInProgress {
		t.Errorf("StartWorkflow() first phase Status = %v, want %v", started.Phases[0].Status, domain.PhaseStatusInProgress)
	}
	if started.Phases[0].StartedAt == nil {
		t.Error("StartWorkflow() first phase StartedAt should be set")
	}
}

func TestWorkflowService_StartWorkflow_AlreadyStarted(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)
	_, _ = svc.StartWorkflow(ctx, wf.ID, "user-789")

	// Try to start again
	_, err := svc.StartWorkflow(ctx, wf.ID, "user-789")
	if err == nil {
		t.Error("StartWorkflow() should fail when workflow already started")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/service/... -run TestWorkflowService_StartWorkflow`

Expected: FAIL with "StartWorkflow not defined"

**Step 3: Add StartWorkflow method**

Add to `internal/service/workflow_service.go`:
```go
// StartWorkflow transitions a workflow from draft to in_progress
func (s *WorkflowService) StartWorkflow(ctx context.Context, workflowID, userID string) (*domain.Workflow, error) {
	wf, err := s.repo.GetWorkflow(ctx, workflowID)
	if err != nil {
		return nil, err
	}

	if wf.Status != domain.StatusDraft {
		return nil, errors.New("workflow already started")
	}

	now := time.Now()
	wf.Status = domain.StatusInProgress
	wf.UpdatedAt = now

	// Start the first phase
	wf.Phases[0].Status = domain.PhaseStatusInProgress
	wf.Phases[0].StartedAt = &now

	if err := s.repo.UpdateWorkflow(ctx, wf); err != nil {
		return nil, err
	}

	// Record events
	_ = s.repo.AppendEvent(ctx, &domain.Event{
		ID:         generateID(),
		WorkflowID: wf.ID,
		Type:       domain.EventPhaseStarted,
		ActorType:  "user",
		ActorID:    userID,
		Data:       map[string]any{"phase": string(domain.PhaseRequirements)},
		Timestamp:  now,
	})

	return wf, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/service/... -run TestWorkflowService_StartWorkflow`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/workflow_service.go internal/service/workflow_service_test.go
git commit -m "feat: add StartWorkflow to WorkflowService"
```

---

## Task 12: Workflow Service - Complete Phase and Transition

**Files:**
- Modify: `internal/service/workflow_service.go`
- Modify: `internal/service/workflow_service_test.go`

**Step 1: Write the failing test**

Add to `internal/service/workflow_service_test.go`:
```go
func TestWorkflowService_CompletePhase(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	// Create and start workflow
	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)
	wf, _ = svc.StartWorkflow(ctx, wf.ID, "user-789")

	// Complete the requirements phase
	completed, err := svc.CompletePhase(ctx, wf.ID, domain.PhaseRequirements, "user-789")
	if err != nil {
		t.Fatalf("CompletePhase() error = %v", err)
	}

	// First phase should be completed
	if completed.Phases[0].Status != domain.PhaseStatusCompleted {
		t.Errorf("CompletePhase() first phase Status = %v, want %v", completed.Phases[0].Status, domain.PhaseStatusCompleted)
	}
	if completed.Phases[0].CompletedAt == nil {
		t.Error("CompletePhase() first phase CompletedAt should be set")
	}

	// Second phase should now be in progress
	if completed.CurrentPhase != domain.PhaseArchitecture {
		t.Errorf("CompletePhase() CurrentPhase = %v, want %v", completed.CurrentPhase, domain.PhaseArchitecture)
	}
	if completed.Phases[1].Status != domain.PhaseStatusInProgress {
		t.Errorf("CompletePhase() second phase Status = %v, want %v", completed.Phases[1].Status, domain.PhaseStatusInProgress)
	}
}

func TestWorkflowService_CompletePhase_FinalPhase(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	// Create and start workflow
	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)
	wf, _ = svc.StartWorkflow(ctx, wf.ID, "user-789")

	// Complete all phases
	wf, _ = svc.CompletePhase(ctx, wf.ID, domain.PhaseRequirements, "user-789")
	wf, _ = svc.CompletePhase(ctx, wf.ID, domain.PhaseArchitecture, "user-789")
	wf, _ = svc.CompletePhase(ctx, wf.ID, domain.PhaseCode, "user-789")
	completed, err := svc.CompletePhase(ctx, wf.ID, domain.PhaseSecurityReview, "user-789")
	if err != nil {
		t.Fatalf("CompletePhase() error = %v", err)
	}

	// Workflow should be completed
	if completed.Status != domain.StatusCompleted {
		t.Errorf("CompletePhase() workflow Status = %v, want %v", completed.Status, domain.StatusCompleted)
	}
	if completed.CompletedAt == nil {
		t.Error("CompletePhase() workflow CompletedAt should be set")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/service/... -run TestWorkflowService_CompletePhase`

Expected: FAIL with "CompletePhase not defined"

**Step 3: Add CompletePhase method**

Add to `internal/service/workflow_service.go`:
```go
// CompletePhase marks a phase as completed and transitions to the next phase
func (s *WorkflowService) CompletePhase(ctx context.Context, workflowID string, phase domain.Phase, userID string) (*domain.Workflow, error) {
	wf, err := s.repo.GetWorkflow(ctx, workflowID)
	if err != nil {
		return nil, err
	}

	if wf.CurrentPhase != phase {
		return nil, errors.New("cannot complete a phase that is not current")
	}

	now := time.Now()

	// Find and complete the current phase
	phaseIndex := phase.Order() - 1
	if phaseIndex < 0 || phaseIndex >= len(wf.Phases) {
		return nil, errors.New("invalid phase index")
	}

	wf.Phases[phaseIndex].Status = domain.PhaseStatusCompleted
	wf.Phases[phaseIndex].CompletedAt = &now

	// Record phase completion event
	_ = s.repo.AppendEvent(ctx, &domain.Event{
		ID:         generateID(),
		WorkflowID: wf.ID,
		Type:       domain.EventPhaseCompleted,
		ActorType:  "user",
		ActorID:    userID,
		Data:       map[string]any{"phase": string(phase)},
		Timestamp:  now,
	})

	// Check if there's a next phase
	nextPhase, hasNext := phase.NextPhase()
	if hasNext {
		// Transition to next phase
		wf.CurrentPhase = nextPhase
		nextIndex := nextPhase.Order() - 1
		wf.Phases[nextIndex].Status = domain.PhaseStatusInProgress
		wf.Phases[nextIndex].StartedAt = &now

		// Record phase started event
		_ = s.repo.AppendEvent(ctx, &domain.Event{
			ID:         generateID(),
			WorkflowID: wf.ID,
			Type:       domain.EventPhaseStarted,
			ActorType:  "system",
			ActorID:    "workflow-engine",
			Data:       map[string]any{"phase": string(nextPhase)},
			Timestamp:  now,
		})
	} else {
		// Workflow complete
		wf.Status = domain.StatusCompleted
		wf.CompletedAt = &now

		// Record workflow completed event
		_ = s.repo.AppendEvent(ctx, &domain.Event{
			ID:         generateID(),
			WorkflowID: wf.ID,
			Type:       domain.EventWorkflowCompleted,
			ActorType:  "system",
			ActorID:    "workflow-engine",
			Timestamp:  now,
		})
	}

	wf.UpdatedAt = now

	if err := s.repo.UpdateWorkflow(ctx, wf); err != nil {
		return nil, err
	}

	return wf, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/service/... -run TestWorkflowService_CompletePhase`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/workflow_service.go internal/service/workflow_service_test.go
git commit -m "feat: add CompletePhase with automatic phase transitions"
```

---

## Task 13: Workflow Service - Escalation Handling

**Files:**
- Modify: `internal/service/workflow_service.go`
- Modify: `internal/service/workflow_service_test.go`

**Step 1: Write the failing test**

Add to `internal/service/workflow_service_test.go`:
```go
func TestWorkflowService_CreateEscalation(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	// Create and start workflow
	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)
	wf, _ = svc.StartWorkflow(ctx, wf.ID, "user-789")

	// Create an escalation
	escInput := CreateEscalationInput{
		WorkflowID:   wf.ID,
		ArtifactID:   "art-123",
		ConstraintID: "con-456",
		Attempts: []domain.Attempt{
			{AttemptNumber: 1, Output: "attempt 1", Feedback: "failed"},
			{AttemptNumber: 2, Output: "attempt 2", Feedback: "still failed"},
			{AttemptNumber: 3, Output: "attempt 3", Feedback: "max retries"},
		},
	}

	esc, err := svc.CreateEscalation(ctx, escInput)
	if err != nil {
		t.Fatalf("CreateEscalation() error = %v", err)
	}

	if esc.ID == "" {
		t.Error("CreateEscalation() ID should not be empty")
	}
	if esc.Status != domain.EscalationPending {
		t.Errorf("CreateEscalation() Status = %v, want %v", esc.Status, domain.EscalationPending)
	}

	// Workflow should be blocked
	blockedWf, _ := svc.GetWorkflow(ctx, wf.ID)
	if blockedWf.Status != domain.StatusBlocked {
		t.Errorf("Workflow Status = %v, want %v", blockedWf.Status, domain.StatusBlocked)
	}
}

func TestWorkflowService_ResolveEscalation(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := NewWorkflowService(repo)
	ctx := context.Background()

	// Create, start workflow, and create escalation
	createInput := CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	}
	wf, _ := svc.CreateWorkflow(ctx, createInput)
	wf, _ = svc.StartWorkflow(ctx, wf.ID, "user-789")

	escInput := CreateEscalationInput{
		WorkflowID:   wf.ID,
		ArtifactID:   "art-123",
		ConstraintID: "con-456",
		Attempts:     []domain.Attempt{},
	}
	esc, _ := svc.CreateEscalation(ctx, escInput)

	// Resolve the escalation
	resolveInput := ResolveEscalationInput{
		EscalationID: esc.ID,
		Action:       "guidance",
		UserID:       "user-789",
		Reason:       "Provided clarification",
	}

	resolved, err := svc.ResolveEscalation(ctx, resolveInput)
	if err != nil {
		t.Fatalf("ResolveEscalation() error = %v", err)
	}

	if resolved.Status != domain.EscalationResolved {
		t.Errorf("ResolveEscalation() Status = %v, want %v", resolved.Status, domain.EscalationResolved)
	}
	if resolved.Resolution == nil {
		t.Error("ResolveEscalation() Resolution should be set")
	}

	// Workflow should be unblocked
	unblockedWf, _ := svc.GetWorkflow(ctx, wf.ID)
	if unblockedWf.Status != domain.StatusInProgress {
		t.Errorf("Workflow Status = %v, want %v", unblockedWf.Status, domain.StatusInProgress)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/service/... -run "TestWorkflowService_CreateEscalation|TestWorkflowService_ResolveEscalation"`

Expected: FAIL with "CreateEscalation not defined"

**Step 3: Add escalation methods**

Add to `internal/service/workflow_service.go`:
```go
// CreateEscalationInput contains the data needed to create an escalation
type CreateEscalationInput struct {
	WorkflowID   string
	ArtifactID   string
	ConstraintID string
	Attempts     []domain.Attempt
}

// CreateEscalation creates a new escalation and blocks the workflow
func (s *WorkflowService) CreateEscalation(ctx context.Context, input CreateEscalationInput) (*domain.Escalation, error) {
	// Verify workflow exists
	wf, err := s.repo.GetWorkflow(ctx, input.WorkflowID)
	if err != nil {
		return nil, err
	}

	now := time.Now()

	esc := &domain.Escalation{
		ID:           generateID(),
		WorkflowID:   input.WorkflowID,
		ArtifactID:   input.ArtifactID,
		ConstraintID: input.ConstraintID,
		Attempts:     input.Attempts,
		Status:       domain.EscalationPending,
		CreatedAt:    now,
	}

	if err := esc.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateEscalation(ctx, esc); err != nil {
		return nil, err
	}

	// Block the workflow
	wf.Status = domain.StatusBlocked
	wf.UpdatedAt = now
	if err := s.repo.UpdateWorkflow(ctx, wf); err != nil {
		return nil, err
	}

	// Record event
	_ = s.repo.AppendEvent(ctx, &domain.Event{
		ID:         generateID(),
		WorkflowID: wf.ID,
		Type:       domain.EventEscalationCreated,
		ActorType:  "agent",
		ActorID:    "constraint-validator",
		Data: map[string]any{
			"escalationId": esc.ID,
			"artifactId":   input.ArtifactID,
			"constraintId": input.ConstraintID,
		},
		Timestamp: now,
	})

	return esc, nil
}

// ResolveEscalationInput contains the data needed to resolve an escalation
type ResolveEscalationInput struct {
	EscalationID string
	Action       string // "guidance", "edit", "override"
	UserID       string
	Reason       string
}

// ResolveEscalation resolves an escalation and unblocks the workflow
func (s *WorkflowService) ResolveEscalation(ctx context.Context, input ResolveEscalationInput) (*domain.Escalation, error) {
	esc, err := s.repo.GetEscalation(ctx, input.EscalationID)
	if err != nil {
		return nil, err
	}

	if esc.Status != domain.EscalationPending {
		return nil, errors.New("escalation already resolved")
	}

	now := time.Now()

	esc.Status = domain.EscalationResolved
	if input.Action == "override" {
		esc.Status = domain.EscalationOverridden
	}
	esc.Resolution = &domain.Resolution{
		Action:    input.Action,
		UserID:    input.UserID,
		Reason:    input.Reason,
		Timestamp: now,
	}
	esc.ResolvedAt = &now

	if err := s.repo.UpdateEscalation(ctx, esc); err != nil {
		return nil, err
	}

	// Check if there are other pending escalations for this workflow
	escalations, err := s.repo.ListEscalationsByWorkflow(ctx, esc.WorkflowID)
	if err != nil {
		return nil, err
	}

	hasPending := false
	for _, e := range escalations {
		if e.Status == domain.EscalationPending {
			hasPending = true
			break
		}
	}

	// If no more pending escalations, unblock the workflow
	if !hasPending {
		wf, err := s.repo.GetWorkflow(ctx, esc.WorkflowID)
		if err != nil {
			return nil, err
		}

		wf.Status = domain.StatusInProgress
		wf.UpdatedAt = now
		if err := s.repo.UpdateWorkflow(ctx, wf); err != nil {
			return nil, err
		}
	}

	// Record event
	_ = s.repo.AppendEvent(ctx, &domain.Event{
		ID:         generateID(),
		WorkflowID: esc.WorkflowID,
		Type:       domain.EventEscalationResolved,
		ActorType:  "user",
		ActorID:    input.UserID,
		Data: map[string]any{
			"escalationId": esc.ID,
			"action":       input.Action,
			"reason":       input.Reason,
		},
		Timestamp: now,
	})

	return esc, nil
}

// GetEscalation retrieves an escalation by ID
func (s *WorkflowService) GetEscalation(ctx context.Context, id string) (*domain.Escalation, error) {
	return s.repo.GetEscalation(ctx, id)
}

// ListEscalationsByWorkflow lists all escalations for a workflow
func (s *WorkflowService) ListEscalationsByWorkflow(ctx context.Context, workflowID string) ([]*domain.Escalation, error) {
	return s.repo.ListEscalationsByWorkflow(ctx, workflowID)
}

// ListPendingEscalations lists all pending escalations for an organization
func (s *WorkflowService) ListPendingEscalations(ctx context.Context, orgID string) ([]*domain.Escalation, error) {
	return s.repo.ListPendingEscalations(ctx, orgID)
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/service/... -run "TestWorkflowService_CreateEscalation|TestWorkflowService_ResolveEscalation"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/workflow_service.go internal/service/workflow_service_test.go
git commit -m "feat: add escalation handling to WorkflowService"
```
