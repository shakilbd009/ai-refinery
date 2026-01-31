# Security Review: Data Models

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Define domain types for SecurityFinding and SecurityReview.

**Files:**
- Modify: `internal/domain/workflow.go`

---

## Task 1: Add SecurityFinding Type

**Files:**
- Modify: `internal/domain/workflow.go` (after Escalation type, ~line 180)

**Step 1: Write the test**

Create test file:
- Create: `internal/domain/workflow_test.go`

```go
package domain

import (
	"testing"
	"time"
)

func TestSecurityFinding_Severities(t *testing.T) {
	tests := []struct {
		severity FindingSeverity
		valid    bool
	}{
		{SeverityCritical, true},
		{SeverityHigh, true},
		{SeverityMedium, true},
		{SeverityLow, true},
		{FindingSeverity("unknown"), false},
	}

	validSeverities := map[FindingSeverity]bool{
		SeverityCritical: true,
		SeverityHigh:     true,
		SeverityMedium:   true,
		SeverityLow:      true,
	}

	for _, tt := range tests {
		t.Run(string(tt.severity), func(t *testing.T) {
			_, ok := validSeverities[tt.severity]
			if ok != tt.valid {
				t.Errorf("severity %s: got valid=%v, want %v", tt.severity, ok, tt.valid)
			}
		})
	}
}

func TestSecurityFinding_Categories(t *testing.T) {
	validCategories := map[FindingCategory]bool{
		CategoryInjection:     true,
		CategoryAuthentication: true,
		CategoryDataExposure:  true,
		CategoryAccessControl: true,
		CategoryConfiguration: true,
		CategoryDependencies:  true,
	}

	if len(validCategories) != 6 {
		t.Errorf("expected 6 categories, got %d", len(validCategories))
	}
}

func TestSecurityFinding_Statuses(t *testing.T) {
	validStatuses := map[FindingStatus]bool{
		FindingPending:         true,
		FindingAccepted:        true,
		FindingUserAlternative: true,
	}

	if len(validStatuses) != 3 {
		t.Errorf("expected 3 statuses, got %d", len(validStatuses))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityFinding`

Expected: FAIL - types not defined

**Step 3: Write the implementation**

Add to `internal/domain/workflow.go` after the Escalation type:

```go
// FindingSeverity represents the severity level of a security finding
type FindingSeverity string

const (
	SeverityCritical FindingSeverity = "critical"
	SeverityHigh     FindingSeverity = "high"
	SeverityMedium   FindingSeverity = "medium"
	SeverityLow      FindingSeverity = "low"
)

// FindingCategory represents the category of security vulnerability
type FindingCategory string

const (
	CategoryInjection      FindingCategory = "injection"
	CategoryAuthentication FindingCategory = "authentication"
	CategoryDataExposure   FindingCategory = "data_exposure"
	CategoryAccessControl  FindingCategory = "access_control"
	CategoryConfiguration  FindingCategory = "configuration"
	CategoryDependencies   FindingCategory = "dependencies"
)

// FindingStatus represents the resolution status of a security finding
type FindingStatus string

const (
	FindingPending         FindingStatus = "pending"
	FindingAccepted        FindingStatus = "accepted"
	FindingUserAlternative FindingStatus = "user_alternative"
)

// SecurityFinding represents a security vulnerability found during review
type SecurityFinding struct {
	ID         string `firestore:"id"`
	ProjectID  string `firestore:"projectId"`
	ArtifactID string `firestore:"artifactId"`

	// Issue details
	Category    FindingCategory `firestore:"category"`
	Severity    FindingSeverity `firestore:"severity"`
	Location    string          `firestore:"location"` // file:line
	Description string          `firestore:"description"`

	// Fix
	ProposedPatch string `firestore:"proposedPatch"`

	// Resolution
	Status           FindingStatus `firestore:"status"`
	ResolvedBy       string        `firestore:"resolvedBy"`
	ResolvedAt       *time.Time    `firestore:"resolvedAt"`
	AlternativePatch *string       `firestore:"alternativePatch"` // if user provided alternative

	CreatedAt time.Time `firestore:"createdAt"`
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityFinding`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "$(cat <<'EOF'
feat(domain): add SecurityFinding type for security review

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add SecurityReview Type

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the test**

Add to `internal/domain/workflow_test.go`:

```go
func TestSecurityReview_Statuses(t *testing.T) {
	validStatuses := map[ReviewStatus]bool{
		ReviewInProgress:       true,
		ReviewAwaitingApproval: true,
		ReviewCompleted:        true,
	}

	if len(validStatuses) != 3 {
		t.Errorf("expected 3 review statuses, got %d", len(validStatuses))
	}
}

func TestSecurityReview_CountsMatch(t *testing.T) {
	review := SecurityReview{
		FindingsCount: 5,
		CriticalCount: 1,
		HighCount:     2,
		MediumCount:   1,
		LowCount:      1,
	}

	total := review.CriticalCount + review.HighCount + review.MediumCount + review.LowCount
	if total != review.FindingsCount {
		t.Errorf("counts don't match: %d + %d + %d + %d = %d, want %d",
			review.CriticalCount, review.HighCount, review.MediumCount, review.LowCount,
			total, review.FindingsCount)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityReview`

Expected: FAIL - types not defined

**Step 3: Write the implementation**

Add to `internal/domain/workflow.go` after SecurityFinding:

```go
// ReviewStatus represents the status of a security review
type ReviewStatus string

const (
	ReviewInProgress       ReviewStatus = "in_progress"
	ReviewAwaitingApproval ReviewStatus = "awaiting_approval"
	ReviewCompleted        ReviewStatus = "completed"
)

// SecurityReview represents a security review session for a project
type SecurityReview struct {
	ID         string `firestore:"id"`
	ProjectID  string `firestore:"projectId"`
	WorkflowID string `firestore:"workflowId"`

	// Results
	FindingsCount int `firestore:"findingsCount"`
	CriticalCount int `firestore:"criticalCount"`
	HighCount     int `firestore:"highCount"`
	MediumCount   int `firestore:"mediumCount"`
	LowCount      int `firestore:"lowCount"`

	// Status
	Status ReviewStatus `firestore:"status"`

	StartedAt   time.Time  `firestore:"startedAt"`
	CompletedAt *time.Time `firestore:"completedAt"`
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityReview`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "$(cat <<'EOF'
feat(domain): add SecurityReview type for review sessions

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add Security Event Types

**Files:**
- Modify: `internal/domain/workflow.go`
- Modify: `internal/domain/workflow_test.go`

**Step 1: Write the test**

Add to `internal/domain/workflow_test.go`:

```go
func TestSecurityEventTypes(t *testing.T) {
	securityEvents := []EventType{
		EventSecurityReviewStarted,
		EventSecurityFindingCreated,
		EventSecurityFindingResolved,
		EventSecurityReviewCompleted,
	}

	for _, event := range securityEvents {
		if event == "" {
			t.Errorf("event type should not be empty")
		}
	}

	if len(securityEvents) != 4 {
		t.Errorf("expected 4 security event types, got %d", len(securityEvents))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityEventTypes`

Expected: FAIL - constants not defined

**Step 3: Write the implementation**

Add to the EventType const block in `internal/domain/workflow.go`:

```go
// Security review events
EventSecurityReviewStarted   EventType = "security_review_started"
EventSecurityFindingCreated  EventType = "security_finding_created"
EventSecurityFindingResolved EventType = "security_finding_resolved"
EventSecurityReviewCompleted EventType = "security_review_completed"
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/domain/... -v -run TestSecurityEventTypes`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/workflow.go internal/domain/workflow_test.go
git commit -m "$(cat <<'EOF'
feat(domain): add security review event types

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, you will have:
- `SecurityFinding` type with severity, category, status enums
- `SecurityReview` type for review sessions
- Event types for audit trail
- All types tested

**Next:** Proceed to `02-repository.md`
