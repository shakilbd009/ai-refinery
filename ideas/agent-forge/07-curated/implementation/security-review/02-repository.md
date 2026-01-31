# Security Review: Repository Layer

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add repository interface and methods for SecurityFinding and SecurityReview persistence.

**Prerequisites:** Complete `01-data-models.md`

**Files:**
- Modify: `internal/repository/workflow_repository.go`

---

## Task 1: Add SecurityFinding Repository Methods

**Files:**
- Modify: `internal/repository/workflow_repository.go`
- Create: `internal/repository/workflow_repository_test.go`

**Step 1: Write the test**

Create test file:

```go
package repository

import (
	"context"
	"testing"
	"time"

	"github.com/your-org/agentic-platform/internal/domain"
)

// MockWorkflowRepository for testing interface compliance
type MockWorkflowRepository struct {
	findings map[string]*domain.SecurityFinding
	reviews  map[string]*domain.SecurityReview
}

func NewMockWorkflowRepository() *MockWorkflowRepository {
	return &MockWorkflowRepository{
		findings: make(map[string]*domain.SecurityFinding),
		reviews:  make(map[string]*domain.SecurityReview),
	}
}

func (m *MockWorkflowRepository) CreateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error {
	m.findings[f.ID] = f
	return nil
}

func (m *MockWorkflowRepository) GetSecurityFinding(ctx context.Context, id string) (*domain.SecurityFinding, error) {
	if f, ok := m.findings[id]; ok {
		return f, nil
	}
	return nil, nil
}

func (m *MockWorkflowRepository) UpdateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error {
	m.findings[f.ID] = f
	return nil
}

func (m *MockWorkflowRepository) ListSecurityFindingsByProject(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error) {
	var result []*domain.SecurityFinding
	for _, f := range m.findings {
		if f.ProjectID == projectID {
			result = append(result, f)
		}
	}
	return result, nil
}

func (m *MockWorkflowRepository) ListPendingSecurityFindings(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error) {
	var result []*domain.SecurityFinding
	for _, f := range m.findings {
		if f.ProjectID == projectID && f.Status == domain.FindingPending {
			result = append(result, f)
		}
	}
	return result, nil
}

func TestSecurityFindingRepository(t *testing.T) {
	ctx := context.Background()
	repo := NewMockWorkflowRepository()

	// Create finding
	finding := &domain.SecurityFinding{
		ID:            "finding-1",
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "src/api/users.ts:45",
		Description:   "SQL injection vulnerability",
		ProposedPatch: "Use parameterized query",
		Status:        domain.FindingPending,
		CreatedAt:     time.Now(),
	}

	err := repo.CreateSecurityFinding(ctx, finding)
	if err != nil {
		t.Fatalf("CreateSecurityFinding failed: %v", err)
	}

	// Get finding
	got, err := repo.GetSecurityFinding(ctx, "finding-1")
	if err != nil {
		t.Fatalf("GetSecurityFinding failed: %v", err)
	}
	if got.ID != finding.ID {
		t.Errorf("got ID %s, want %s", got.ID, finding.ID)
	}

	// List by project
	findings, err := repo.ListSecurityFindingsByProject(ctx, "project-1")
	if err != nil {
		t.Fatalf("ListSecurityFindingsByProject failed: %v", err)
	}
	if len(findings) != 1 {
		t.Errorf("got %d findings, want 1", len(findings))
	}

	// List pending
	pending, err := repo.ListPendingSecurityFindings(ctx, "project-1")
	if err != nil {
		t.Fatalf("ListPendingSecurityFindings failed: %v", err)
	}
	if len(pending) != 1 {
		t.Errorf("got %d pending, want 1", len(pending))
	}

	// Update to resolved
	finding.Status = domain.FindingAccepted
	finding.ResolvedBy = "user-1"
	now := time.Now()
	finding.ResolvedAt = &now
	err = repo.UpdateSecurityFinding(ctx, finding)
	if err != nil {
		t.Fatalf("UpdateSecurityFinding failed: %v", err)
	}

	// Verify pending is now empty
	pending, _ = repo.ListPendingSecurityFindings(ctx, "project-1")
	if len(pending) != 0 {
		t.Errorf("got %d pending after resolve, want 0", len(pending))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/repository/... -v -run TestSecurityFindingRepository`

Expected: FAIL - interface methods not in WorkflowRepository

**Step 3: Write the implementation**

Add to `WorkflowRepository` interface in `internal/repository/workflow_repository.go`:

```go
// Security Finding management
CreateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error
GetSecurityFinding(ctx context.Context, id string) (*domain.SecurityFinding, error)
UpdateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error
ListSecurityFindingsByProject(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error)
ListPendingSecurityFindings(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error)
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/repository/... -v -run TestSecurityFindingRepository`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/workflow_repository.go internal/repository/workflow_repository_test.go
git commit -m "$(cat <<'EOF'
feat(repository): add SecurityFinding repository methods

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add SecurityReview Repository Methods

**Files:**
- Modify: `internal/repository/workflow_repository.go`
- Modify: `internal/repository/workflow_repository_test.go`

**Step 1: Write the test**

Add to `internal/repository/workflow_repository_test.go`:

```go
func (m *MockWorkflowRepository) CreateSecurityReview(ctx context.Context, r *domain.SecurityReview) error {
	m.reviews[r.ID] = r
	return nil
}

func (m *MockWorkflowRepository) GetSecurityReview(ctx context.Context, id string) (*domain.SecurityReview, error) {
	if r, ok := m.reviews[id]; ok {
		return r, nil
	}
	return nil, nil
}

func (m *MockWorkflowRepository) GetSecurityReviewByWorkflow(ctx context.Context, workflowID string) (*domain.SecurityReview, error) {
	for _, r := range m.reviews {
		if r.WorkflowID == workflowID {
			return r, nil
		}
	}
	return nil, nil
}

func (m *MockWorkflowRepository) UpdateSecurityReview(ctx context.Context, r *domain.SecurityReview) error {
	m.reviews[r.ID] = r
	return nil
}

func TestSecurityReviewRepository(t *testing.T) {
	ctx := context.Background()
	repo := NewMockWorkflowRepository()

	// Create review
	review := &domain.SecurityReview{
		ID:         "review-1",
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		Status:     domain.ReviewInProgress,
		StartedAt:  time.Now(),
	}

	err := repo.CreateSecurityReview(ctx, review)
	if err != nil {
		t.Fatalf("CreateSecurityReview failed: %v", err)
	}

	// Get by ID
	got, err := repo.GetSecurityReview(ctx, "review-1")
	if err != nil {
		t.Fatalf("GetSecurityReview failed: %v", err)
	}
	if got.ID != review.ID {
		t.Errorf("got ID %s, want %s", got.ID, review.ID)
	}

	// Get by workflow
	byWorkflow, err := repo.GetSecurityReviewByWorkflow(ctx, "workflow-1")
	if err != nil {
		t.Fatalf("GetSecurityReviewByWorkflow failed: %v", err)
	}
	if byWorkflow.WorkflowID != "workflow-1" {
		t.Errorf("got workflow %s, want workflow-1", byWorkflow.WorkflowID)
	}

	// Update with counts
	review.FindingsCount = 3
	review.CriticalCount = 1
	review.HighCount = 2
	review.Status = domain.ReviewAwaitingApproval
	err = repo.UpdateSecurityReview(ctx, review)
	if err != nil {
		t.Fatalf("UpdateSecurityReview failed: %v", err)
	}

	// Verify update
	updated, _ := repo.GetSecurityReview(ctx, "review-1")
	if updated.FindingsCount != 3 {
		t.Errorf("got findings count %d, want 3", updated.FindingsCount)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/repository/... -v -run TestSecurityReviewRepository`

Expected: FAIL - interface methods not defined

**Step 3: Write the implementation**

Add to `WorkflowRepository` interface in `internal/repository/workflow_repository.go`:

```go
// Security Review management
CreateSecurityReview(ctx context.Context, r *domain.SecurityReview) error
GetSecurityReview(ctx context.Context, id string) (*domain.SecurityReview, error)
GetSecurityReviewByWorkflow(ctx context.Context, workflowID string) (*domain.SecurityReview, error)
UpdateSecurityReview(ctx context.Context, r *domain.SecurityReview) error
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/repository/... -v -run TestSecurityReviewRepository`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/workflow_repository.go internal/repository/workflow_repository_test.go
git commit -m "$(cat <<'EOF'
feat(repository): add SecurityReview repository methods

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, the `WorkflowRepository` interface will include:

```go
// Security Finding management
CreateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error
GetSecurityFinding(ctx context.Context, id string) (*domain.SecurityFinding, error)
UpdateSecurityFinding(ctx context.Context, f *domain.SecurityFinding) error
ListSecurityFindingsByProject(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error)
ListPendingSecurityFindings(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error)

// Security Review management
CreateSecurityReview(ctx context.Context, r *domain.SecurityReview) error
GetSecurityReview(ctx context.Context, id string) (*domain.SecurityReview, error)
GetSecurityReviewByWorkflow(ctx context.Context, workflowID string) (*domain.SecurityReview, error)
UpdateSecurityReview(ctx context.Context, r *domain.SecurityReview) error
```

**Next:** Proceed to `03-service.md`
