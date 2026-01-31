# Domain Models (Tasks 1-5)

> Back to [Overview](./00-overview.md)

---

## Task 1: Workflow Domain Models

**Files:**
- Create: `internal/domain/workflow.go`
- Create: `internal/domain/workflow_test.go`

**Step 1: Write the failing test for Phase enum**

Create `internal/domain/workflow_test.go`:
```go
package domain

import "testing"

func TestPhase_IsValid(t *testing.T) {
	tests := []struct {
		phase Phase
		want  bool
	}{
		{PhaseRequirements, true},
		{PhaseArchitecture, true},
		{PhaseCode, true},
		{PhaseSecurityReview, true},
		{Phase("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.phase.IsValid(); got != tt.want {
			t.Errorf("Phase(%q).IsValid() = %v, want %v", tt.phase, got, tt.want)
		}
	}
}

func TestWorkflowStatus_IsValid(t *testing.T) {
	tests := []struct {
		status WorkflowStatus
		want   bool
	}{
		{StatusDraft, true},
		{StatusInProgress, true},
		{StatusAwaitingReview, true},
		{StatusAwaitingApproval, true},
		{StatusBlocked, true},
		{StatusCompleted, true},
		{StatusCancelled, true},
		{WorkflowStatus("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.status.IsValid(); got != tt.want {
			t.Errorf("WorkflowStatus(%q).IsValid() = %v, want %v", tt.status, got, tt.want)
		}
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/domain/... -run TestPhase`

Expected: FAIL with "undefined: Phase"

**Step 3: Write Phase and WorkflowStatus enums**

Create `internal/domain/workflow.go`:
```go
package domain

import (
	"errors"
	"time"
)

// Phase represents workflow phases
type Phase string

const (
	PhaseRequirements   Phase = "requirements"
	PhaseArchitecture   Phase = "architecture"
	PhaseCode           Phase = "code"
	PhaseSecurityReview Phase = "security_review"
)

func (p Phase) IsValid() bool {
	switch p {
	case PhaseRequirements, PhaseArchitecture, PhaseCode, PhaseSecurityReview:
		return true
	}
	return false
}

// PhaseOrder returns the numeric order of a phase (1-4)
func (p Phase) Order() int {
	switch p {
	case PhaseRequirements:
		return 1
	case PhaseArchitecture:
		return 2
	case PhaseCode:
		return 3
	case PhaseSecurityReview:
		return 4
	}
	return 0
}

// NextPhase returns the next phase in the pipeline
func (p Phase) NextPhase() (Phase, bool) {
	switch p {
	case PhaseRequirements:
		return PhaseArchitecture, true
	case PhaseArchitecture:
		return PhaseCode, true
	case PhaseCode:
		return PhaseSecurityReview, true
	case PhaseSecurityReview:
		return "", false
	}
	return "", false
}

// WorkflowStatus represents the overall workflow state
type WorkflowStatus string

const (
	StatusDraft            WorkflowStatus = "draft"
	StatusInProgress       WorkflowStatus = "in_progress"
	StatusAwaitingReview   WorkflowStatus = "awaiting_review"
	StatusAwaitingApproval WorkflowStatus = "awaiting_approval"
	StatusBlocked          WorkflowStatus = "blocked"
	StatusCompleted        WorkflowStatus = "completed"
	StatusCancelled        WorkflowStatus = "cancelled"
)

func (s WorkflowStatus) IsValid() bool {
	switch s {
	case StatusDraft, StatusInProgress, StatusAwaitingReview,
		StatusAwaitingApproval, StatusBlocked, StatusCompleted, StatusCancelled:
		return true
	}
	return false
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/domain/... -run "TestPhase|TestWorkflowStatus"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "feat: add Phase and WorkflowStatus enums for workflow"
```

---

## Task 2: PhaseStatus and TaskStatus Enums

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the failing test**

Add to `internal/domain/workflow_test.go`:
```go
func TestPhaseStatus_IsValid(t *testing.T) {
	tests := []struct {
		status PhaseStatus
		want   bool
	}{
		{PhaseStatusPending, true},
		{PhaseStatusInProgress, true},
		{PhaseStatusAwaitingApproval, true},
		{PhaseStatusCompleted, true},
		{PhaseStatus("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.status.IsValid(); got != tt.want {
			t.Errorf("PhaseStatus(%q).IsValid() = %v, want %v", tt.status, got, tt.want)
		}
	}
}

func TestTaskStatus_IsValid(t *testing.T) {
	tests := []struct {
		status TaskStatus
		want   bool
	}{
		{TaskStatusPending, true},
		{TaskStatusInProgress, true},
		{TaskStatusAwaitingApproval, true},
		{TaskStatusCompleted, true},
		{TaskStatusBlocked, true},
		{TaskStatus("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.status.IsValid(); got != tt.want {
			t.Errorf("TaskStatus(%q).IsValid() = %v, want %v", tt.status, got, tt.want)
		}
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/domain/... -run "TestPhaseStatus|TestTaskStatus"`

Expected: FAIL with "undefined: PhaseStatus"

**Step 3: Write PhaseStatus and TaskStatus enums**

Add to `internal/domain/workflow.go`:
```go
// PhaseStatus represents the state of a single phase
type PhaseStatus string

const (
	PhaseStatusPending          PhaseStatus = "pending"
	PhaseStatusInProgress       PhaseStatus = "in_progress"
	PhaseStatusAwaitingApproval PhaseStatus = "awaiting_approval"
	PhaseStatusCompleted        PhaseStatus = "completed"
)

func (s PhaseStatus) IsValid() bool {
	switch s {
	case PhaseStatusPending, PhaseStatusInProgress, PhaseStatusAwaitingApproval, PhaseStatusCompleted:
		return true
	}
	return false
}

// TaskStatus represents the state of a task within a phase
type TaskStatus string

const (
	TaskStatusPending          TaskStatus = "pending"
	TaskStatusInProgress       TaskStatus = "in_progress"
	TaskStatusAwaitingApproval TaskStatus = "awaiting_approval"
	TaskStatusCompleted        TaskStatus = "completed"
	TaskStatusBlocked          TaskStatus = "blocked"
)

func (s TaskStatus) IsValid() bool {
	switch s {
	case TaskStatusPending, TaskStatusInProgress, TaskStatusAwaitingApproval,
		TaskStatusCompleted, TaskStatusBlocked:
		return true
	}
	return false
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/domain/... -run "TestPhaseStatus|TestTaskStatus"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "feat: add PhaseStatus and TaskStatus enums"
```

---

## Task 3: Workflow Struct with Validation

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the failing test**

Add to `internal/domain/workflow_test.go`:
```go
func TestWorkflow_Validate(t *testing.T) {
	tests := []struct {
		name    string
		wf      Workflow
		wantErr bool
	}{
		{
			name: "valid workflow",
			wf: Workflow{
				ID:           "wf-123",
				ProjectID:    "proj-456",
				OrgID:        "org-789",
				Status:       StatusDraft,
				CurrentPhase: PhaseRequirements,
			},
			wantErr: false,
		},
		{
			name: "missing project ID",
			wf: Workflow{
				ID:           "wf-123",
				OrgID:        "org-789",
				Status:       StatusDraft,
				CurrentPhase: PhaseRequirements,
			},
			wantErr: true,
		},
		{
			name: "missing org ID",
			wf: Workflow{
				ID:           "wf-123",
				ProjectID:    "proj-456",
				Status:       StatusDraft,
				CurrentPhase: PhaseRequirements,
			},
			wantErr: true,
		},
		{
			name: "invalid status",
			wf: Workflow{
				ID:           "wf-123",
				ProjectID:    "proj-456",
				OrgID:        "org-789",
				Status:       WorkflowStatus("invalid"),
				CurrentPhase: PhaseRequirements,
			},
			wantErr: true,
		},
		{
			name: "invalid phase",
			wf: Workflow{
				ID:           "wf-123",
				ProjectID:    "proj-456",
				OrgID:        "org-789",
				Status:       StatusDraft,
				CurrentPhase: Phase("invalid"),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.wf.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Workflow.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/domain/... -run TestWorkflow_Validate`

Expected: FAIL with "undefined: Workflow"

**Step 3: Write Workflow struct**

Add to `internal/domain/workflow.go`:
```go
// Task represents a work item within a phase
type Task struct {
	ID          string     `json:"id" firestore:"id"`
	Name        string     `json:"name" firestore:"name"`
	Status      TaskStatus `json:"status" firestore:"status"`
	ArtifactIDs []string   `json:"artifactIds" firestore:"artifactIds"`
	LockedBy    *string    `json:"lockedBy,omitempty" firestore:"lockedBy"`
	LockedAt    *time.Time `json:"lockedAt,omitempty" firestore:"lockedAt"`
}

// PhaseState tracks the state of a single phase
type PhaseState struct {
	Phase       Phase       `json:"phase" firestore:"phase"`
	Status      PhaseStatus `json:"status" firestore:"status"`
	Tasks       []Task      `json:"tasks" firestore:"tasks"`
	StartedAt   *time.Time  `json:"startedAt,omitempty" firestore:"startedAt"`
	CompletedAt *time.Time  `json:"completedAt,omitempty" firestore:"completedAt"`
}

// Workflow represents the overall workflow for a project
type Workflow struct {
	ID           string         `json:"id" firestore:"id"`
	ProjectID    string         `json:"projectId" firestore:"projectId"`
	OrgID        string         `json:"orgId" firestore:"orgId"`
	Status       WorkflowStatus `json:"status" firestore:"status"`
	CurrentPhase Phase          `json:"currentPhase" firestore:"currentPhase"`
	Phases       []PhaseState   `json:"phases" firestore:"phases"`
	CreatedAt    time.Time      `json:"createdAt" firestore:"createdAt"`
	UpdatedAt    time.Time      `json:"updatedAt" firestore:"updatedAt"`
	CompletedAt  *time.Time     `json:"completedAt,omitempty" firestore:"completedAt"`
}

func (w *Workflow) Validate() error {
	if w.ProjectID == "" {
		return errors.New("projectId is required")
	}
	if w.OrgID == "" {
		return errors.New("orgId is required")
	}
	if !w.Status.IsValid() {
		return errors.New("invalid status")
	}
	if !w.CurrentPhase.IsValid() {
		return errors.New("invalid currentPhase")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/domain/... -run TestWorkflow_Validate`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "feat: add Workflow, PhaseState, and Task structs"
```

---

## Task 4: Escalation Domain Model

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the failing test**

Add to `internal/domain/workflow_test.go`:
```go
func TestEscalationStatus_IsValid(t *testing.T) {
	tests := []struct {
		status EscalationStatus
		want   bool
	}{
		{EscalationPending, true},
		{EscalationResolved, true},
		{EscalationOverridden, true},
		{EscalationStatus("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.status.IsValid(); got != tt.want {
			t.Errorf("EscalationStatus(%q).IsValid() = %v, want %v", tt.status, got, tt.want)
		}
	}
}

func TestEscalation_Validate(t *testing.T) {
	tests := []struct {
		name    string
		esc     Escalation
		wantErr bool
	}{
		{
			name: "valid escalation",
			esc: Escalation{
				ID:           "esc-123",
				WorkflowID:   "wf-456",
				ArtifactID:   "art-789",
				ConstraintID: "con-012",
				Status:       EscalationPending,
			},
			wantErr: false,
		},
		{
			name: "missing workflow ID",
			esc: Escalation{
				ID:           "esc-123",
				ArtifactID:   "art-789",
				ConstraintID: "con-012",
				Status:       EscalationPending,
			},
			wantErr: true,
		},
		{
			name: "missing artifact ID",
			esc: Escalation{
				ID:           "esc-123",
				WorkflowID:   "wf-456",
				ConstraintID: "con-012",
				Status:       EscalationPending,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.esc.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Escalation.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/domain/... -run "TestEscalationStatus|TestEscalation_Validate"`

Expected: FAIL with "undefined: EscalationStatus"

**Step 3: Write Escalation structs**

Add to `internal/domain/workflow.go`:
```go
// EscalationStatus represents the state of an escalation
type EscalationStatus string

const (
	EscalationPending    EscalationStatus = "pending"
	EscalationResolved   EscalationStatus = "resolved"
	EscalationOverridden EscalationStatus = "overridden"
)

func (s EscalationStatus) IsValid() bool {
	switch s {
	case EscalationPending, EscalationResolved, EscalationOverridden:
		return true
	}
	return false
}

// Attempt records an agent's attempt to satisfy a constraint
type Attempt struct {
	AttemptNumber int       `json:"attemptNumber" firestore:"attemptNumber"`
	Output        string    `json:"output" firestore:"output"`
	Feedback      string    `json:"feedback" firestore:"feedback"`
	Timestamp     time.Time `json:"timestamp" firestore:"timestamp"`
}

// Resolution records how an escalation was resolved
type Resolution struct {
	Action    string    `json:"action" firestore:"action"` // guidance, edit, override
	UserID    string    `json:"userId" firestore:"userId"`
	Reason    string    `json:"reason" firestore:"reason"`
	Timestamp time.Time `json:"timestamp" firestore:"timestamp"`
}

// Escalation represents a constraint violation requiring user attention
type Escalation struct {
	ID           string           `json:"id" firestore:"id"`
	WorkflowID   string           `json:"workflowId" firestore:"workflowId"`
	ArtifactID   string           `json:"artifactId" firestore:"artifactId"`
	ConstraintID string           `json:"constraintId" firestore:"constraintId"`
	Attempts     []Attempt        `json:"attempts" firestore:"attempts"`
	Status       EscalationStatus `json:"status" firestore:"status"`
	Resolution   *Resolution      `json:"resolution,omitempty" firestore:"resolution"`
	CreatedAt    time.Time        `json:"createdAt" firestore:"createdAt"`
	ResolvedAt   *time.Time       `json:"resolvedAt,omitempty" firestore:"resolvedAt"`
}

func (e *Escalation) Validate() error {
	if e.WorkflowID == "" {
		return errors.New("workflowId is required")
	}
	if e.ArtifactID == "" {
		return errors.New("artifactId is required")
	}
	if e.ConstraintID == "" {
		return errors.New("constraintId is required")
	}
	if !e.Status.IsValid() {
		return errors.New("invalid status")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/domain/... -run "TestEscalationStatus|TestEscalation_Validate"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "feat: add Escalation domain model"
```

---

## Task 5: Event Domain Model for Event Sourcing

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the failing test**

Add to `internal/domain/workflow_test.go`:
```go
func TestEventType_IsValid(t *testing.T) {
	tests := []struct {
		eventType EventType
		want      bool
	}{
		{EventWorkflowCreated, true},
		{EventPhaseStarted, true},
		{EventPhaseCompleted, true},
		{EventArtifactCreated, true},
		{EventArtifactApproved, true},
		{EventArtifactRejected, true},
		{EventEscalationCreated, true},
		{EventEscalationResolved, true},
		{EventType("invalid"), false},
	}

	for _, tt := range tests {
		if got := tt.eventType.IsValid(); got != tt.want {
			t.Errorf("EventType(%q).IsValid() = %v, want %v", tt.eventType, got, tt.want)
		}
	}
}

func TestEvent_Validate(t *testing.T) {
	tests := []struct {
		name    string
		event   Event
		wantErr bool
	}{
		{
			name: "valid event",
			event: Event{
				ID:         "evt-123",
				WorkflowID: "wf-456",
				Type:       EventWorkflowCreated,
				ActorType:  "user",
				ActorID:    "user-789",
			},
			wantErr: false,
		},
		{
			name: "missing workflow ID",
			event: Event{
				ID:        "evt-123",
				Type:      EventWorkflowCreated,
				ActorType: "user",
				ActorID:   "user-789",
			},
			wantErr: true,
		},
		{
			name: "invalid event type",
			event: Event{
				ID:         "evt-123",
				WorkflowID: "wf-456",
				Type:       EventType("invalid"),
				ActorType:  "user",
				ActorID:    "user-789",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.event.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Event.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/domain/... -run "TestEventType|TestEvent_Validate"`

Expected: FAIL with "undefined: EventType"

**Step 3: Write Event structs**

Add to `internal/domain/workflow.go`:
```go
// EventType categorizes workflow events
type EventType string

const (
	EventWorkflowCreated    EventType = "workflow_created"
	EventWorkflowCompleted  EventType = "workflow_completed"
	EventWorkflowCancelled  EventType = "workflow_cancelled"
	EventPhaseStarted       EventType = "phase_started"
	EventPhaseCompleted     EventType = "phase_completed"
	EventArtifactCreated    EventType = "artifact_created"
	EventArtifactApproved   EventType = "artifact_approved"
	EventArtifactRejected   EventType = "artifact_rejected"
	EventEscalationCreated  EventType = "escalation_created"
	EventEscalationResolved EventType = "escalation_resolved"
)

func (t EventType) IsValid() bool {
	switch t {
	case EventWorkflowCreated, EventWorkflowCompleted, EventWorkflowCancelled,
		EventPhaseStarted, EventPhaseCompleted,
		EventArtifactCreated, EventArtifactApproved, EventArtifactRejected,
		EventEscalationCreated, EventEscalationResolved:
		return true
	}
	return false
}

// Event represents an immutable workflow event for event sourcing
type Event struct {
	ID         string         `json:"id" firestore:"id"`
	WorkflowID string         `json:"workflowId" firestore:"workflowId"`
	Type       EventType      `json:"type" firestore:"type"`
	ActorType  string         `json:"actorType" firestore:"actorType"` // "user" or "agent"
	ActorID    string         `json:"actorId" firestore:"actorId"`
	Data       map[string]any `json:"data" firestore:"data"`
	Timestamp  time.Time      `json:"timestamp" firestore:"timestamp"`
}

func (e *Event) Validate() error {
	if e.WorkflowID == "" {
		return errors.New("workflowId is required")
	}
	if !e.Type.IsValid() {
		return errors.New("invalid event type")
	}
	if e.ActorType == "" {
		return errors.New("actorType is required")
	}
	if e.ActorID == "" {
		return errors.New("actorId is required")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/domain/... -run "TestEventType|TestEvent_Validate"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "feat: add Event domain model for event sourcing"
```
