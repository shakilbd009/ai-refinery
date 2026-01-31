# Security Review: Service Layer

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add service layer methods for security review orchestration.

**Prerequisites:** Complete `01-data-models.md` and `02-repository.md`

**Files:**
- Create: `internal/service/security_service.go`
- Create: `internal/service/security_service_test.go`

---

## Task 1: Create SecurityService Structure

**Files:**
- Create: `internal/service/security_service.go`
- Create: `internal/service/security_service_test.go`

**Step 1: Write the test**

```go
package service

import (
	"context"
	"testing"

	"github.com/your-org/agentic-platform/internal/domain"
	"github.com/your-org/agentic-platform/internal/repository"
)

func TestNewSecurityService(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	if svc == nil {
		t.Fatal("NewSecurityService returned nil")
	}
	if svc.repo == nil {
		t.Error("repo should not be nil")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestNewSecurityService`

Expected: FAIL - SecurityService not defined

**Step 3: Write the implementation**

Create `internal/service/security_service.go`:

```go
package service

import (
	"context"

	"github.com/your-org/agentic-platform/internal/domain"
	"github.com/your-org/agentic-platform/internal/repository"
)

// SecurityService handles security review business logic
type SecurityService struct {
	repo repository.WorkflowRepository
}

// NewSecurityService creates a new security service
func NewSecurityService(repo repository.WorkflowRepository) *SecurityService {
	return &SecurityService{repo: repo}
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestNewSecurityService`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add SecurityService skeleton

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add StartSecurityReview Method

**Files:**
- Modify: `internal/service/security_service.go`
- Modify: `internal/service/security_service_test.go`

**Step 1: Write the test**

Add to `internal/service/security_service_test.go`:

```go
func TestSecurityService_StartSecurityReview(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	input := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}

	review, err := svc.StartSecurityReview(ctx, input)
	if err != nil {
		t.Fatalf("StartSecurityReview failed: %v", err)
	}

	if review.ID == "" {
		t.Error("review ID should not be empty")
	}
	if review.ProjectID != input.ProjectID {
		t.Errorf("got project %s, want %s", review.ProjectID, input.ProjectID)
	}
	if review.Status != domain.ReviewInProgress {
		t.Errorf("got status %s, want %s", review.Status, domain.ReviewInProgress)
	}
	if review.StartedAt.IsZero() {
		t.Error("StartedAt should be set")
	}
}

func TestSecurityService_StartSecurityReview_AlreadyExists(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	input := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}

	// Start first review
	_, err := svc.StartSecurityReview(ctx, input)
	if err != nil {
		t.Fatalf("first StartSecurityReview failed: %v", err)
	}

	// Try to start another - should return existing
	review2, err := svc.StartSecurityReview(ctx, input)
	if err != nil {
		t.Fatalf("second StartSecurityReview failed: %v", err)
	}

	// Should return existing review, not create new
	if review2.Status != domain.ReviewInProgress {
		t.Errorf("got status %s, want in_progress", review2.Status)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_StartSecurityReview`

Expected: FAIL - method not defined

**Step 3: Write the implementation**

Add to `internal/service/security_service.go`:

```go
import (
	"time"

	"github.com/google/uuid"
)

// StartSecurityReviewInput contains parameters for starting a security review
type StartSecurityReviewInput struct {
	ProjectID  string
	WorkflowID string
	OrgID      string
}

// StartSecurityReview initiates a new security review for a workflow
func (s *SecurityService) StartSecurityReview(ctx context.Context, input StartSecurityReviewInput) (*domain.SecurityReview, error) {
	// Check if review already exists for this workflow
	existing, err := s.repo.GetSecurityReviewByWorkflow(ctx, input.WorkflowID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	// Create new review
	review := &domain.SecurityReview{
		ID:         uuid.New().String(),
		ProjectID:  input.ProjectID,
		WorkflowID: input.WorkflowID,
		Status:     domain.ReviewInProgress,
		StartedAt:  time.Now(),
	}

	if err := s.repo.CreateSecurityReview(ctx, review); err != nil {
		return nil, err
	}

	// Log event
	event := &domain.Event{
		ID:         uuid.New().String(),
		WorkflowID: input.WorkflowID,
		Type:       domain.EventSecurityReviewStarted,
		ActorType:  "system",
		ActorID:    "security-agent",
		Data: map[string]any{
			"reviewId":  review.ID,
			"projectId": input.ProjectID,
		},
		Timestamp: time.Now(),
	}
	_ = s.repo.AppendEvent(ctx, event) // Best effort

	return review, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_StartSecurityReview`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add StartSecurityReview method

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add CreateFinding Method

**Files:**
- Modify: `internal/service/security_service.go`
- Modify: `internal/service/security_service_test.go`

**Step 1: Write the test**

Add to `internal/service/security_service_test.go`:

```go
func TestSecurityService_CreateFinding(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	// First start a review
	reviewInput := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}
	review, _ := svc.StartSecurityReview(ctx, reviewInput)

	// Create a finding
	input := CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "src/api/users.ts:45",
		Description:   "SQL injection vulnerability",
		ProposedPatch: "Use parameterized query",
	}

	finding, err := svc.CreateFinding(ctx, input)
	if err != nil {
		t.Fatalf("CreateFinding failed: %v", err)
	}

	if finding.ID == "" {
		t.Error("finding ID should not be empty")
	}
	if finding.Status != domain.FindingPending {
		t.Errorf("got status %s, want pending", finding.Status)
	}
	if finding.Severity != domain.SeverityCritical {
		t.Errorf("got severity %s, want critical", finding.Severity)
	}

	// Verify review counts updated
	updatedReview, _ := repo.GetSecurityReview(ctx, review.ID)
	if updatedReview.FindingsCount != 1 {
		t.Errorf("got findings count %d, want 1", updatedReview.FindingsCount)
	}
	if updatedReview.CriticalCount != 1 {
		t.Errorf("got critical count %d, want 1", updatedReview.CriticalCount)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_CreateFinding`

Expected: FAIL - method not defined

**Step 3: Write the implementation**

Add to `internal/service/security_service.go`:

```go
// CreateFindingInput contains parameters for creating a security finding
type CreateFindingInput struct {
	ReviewID      string
	ProjectID     string
	ArtifactID    string
	Category      domain.FindingCategory
	Severity      domain.FindingSeverity
	Location      string
	Description   string
	ProposedPatch string
}

// CreateFinding creates a new security finding and updates review counts
func (s *SecurityService) CreateFinding(ctx context.Context, input CreateFindingInput) (*domain.SecurityFinding, error) {
	finding := &domain.SecurityFinding{
		ID:            uuid.New().String(),
		ProjectID:     input.ProjectID,
		ArtifactID:    input.ArtifactID,
		Category:      input.Category,
		Severity:      input.Severity,
		Location:      input.Location,
		Description:   input.Description,
		ProposedPatch: input.ProposedPatch,
		Status:        domain.FindingPending,
		CreatedAt:     time.Now(),
	}

	if err := s.repo.CreateSecurityFinding(ctx, finding); err != nil {
		return nil, err
	}

	// Update review counts
	review, err := s.repo.GetSecurityReview(ctx, input.ReviewID)
	if err != nil {
		return nil, err
	}
	if review != nil {
		review.FindingsCount++
		switch input.Severity {
		case domain.SeverityCritical:
			review.CriticalCount++
		case domain.SeverityHigh:
			review.HighCount++
		case domain.SeverityMedium:
			review.MediumCount++
		case domain.SeverityLow:
			review.LowCount++
		}
		review.Status = domain.ReviewAwaitingApproval
		_ = s.repo.UpdateSecurityReview(ctx, review)
	}

	return finding, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_CreateFinding`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add CreateFinding method with review count updates

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add AcceptFinding Method

**Files:**
- Modify: `internal/service/security_service.go`
- Modify: `internal/service/security_service_test.go`

**Step 1: Write the test**

Add to `internal/service/security_service_test.go`:

```go
func TestSecurityService_AcceptFinding(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	// Setup: create review and finding
	reviewInput := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}
	review, _ := svc.StartSecurityReview(ctx, reviewInput)

	findingInput := CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "src/api/users.ts:45",
		Description:   "SQL injection vulnerability",
		ProposedPatch: "Use parameterized query",
	}
	finding, _ := svc.CreateFinding(ctx, findingInput)

	// Accept the finding
	input := AcceptFindingInput{
		FindingID: finding.ID,
		UserID:    "user-1",
	}

	updated, err := svc.AcceptFinding(ctx, input)
	if err != nil {
		t.Fatalf("AcceptFinding failed: %v", err)
	}

	if updated.Status != domain.FindingAccepted {
		t.Errorf("got status %s, want accepted", updated.Status)
	}
	if updated.ResolvedBy != "user-1" {
		t.Errorf("got resolved by %s, want user-1", updated.ResolvedBy)
	}
	if updated.ResolvedAt == nil {
		t.Error("ResolvedAt should be set")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_AcceptFinding`

Expected: FAIL - method not defined

**Step 3: Write the implementation**

Add to `internal/service/security_service.go`:

```go
// AcceptFindingInput contains parameters for accepting a security finding
type AcceptFindingInput struct {
	FindingID string
	UserID    string
}

// AcceptFinding marks a security finding as accepted (patch approved)
func (s *SecurityService) AcceptFinding(ctx context.Context, input AcceptFindingInput) (*domain.SecurityFinding, error) {
	finding, err := s.repo.GetSecurityFinding(ctx, input.FindingID)
	if err != nil {
		return nil, err
	}
	if finding == nil {
		return nil, fmt.Errorf("finding not found: %s", input.FindingID)
	}

	now := time.Now()
	finding.Status = domain.FindingAccepted
	finding.ResolvedBy = input.UserID
	finding.ResolvedAt = &now

	if err := s.repo.UpdateSecurityFinding(ctx, finding); err != nil {
		return nil, err
	}

	return finding, nil
}
```

Add `"fmt"` to imports.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_AcceptFinding`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add AcceptFinding method

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Add ProvideAlternative Method

**Files:**
- Modify: `internal/service/security_service.go`
- Modify: `internal/service/security_service_test.go`

**Step 1: Write the test**

Add to `internal/service/security_service_test.go`:

```go
func TestSecurityService_ProvideAlternative(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	// Setup: create review and finding
	reviewInput := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}
	review, _ := svc.StartSecurityReview(ctx, reviewInput)

	findingInput := CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "src/api/users.ts:45",
		Description:   "SQL injection vulnerability",
		ProposedPatch: "Use parameterized query",
	}
	finding, _ := svc.CreateFinding(ctx, findingInput)

	// Provide alternative
	alternativePatch := "Use ORM instead of raw SQL"
	input := ProvideAlternativeInput{
		FindingID:        finding.ID,
		UserID:           "user-1",
		AlternativePatch: alternativePatch,
	}

	updated, err := svc.ProvideAlternative(ctx, input)
	if err != nil {
		t.Fatalf("ProvideAlternative failed: %v", err)
	}

	if updated.Status != domain.FindingUserAlternative {
		t.Errorf("got status %s, want user_alternative", updated.Status)
	}
	if updated.AlternativePatch == nil || *updated.AlternativePatch != alternativePatch {
		t.Errorf("alternative patch not set correctly")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_ProvideAlternative`

Expected: FAIL - method not defined

**Step 3: Write the implementation**

Add to `internal/service/security_service.go`:

```go
// ProvideAlternativeInput contains parameters for providing an alternative fix
type ProvideAlternativeInput struct {
	FindingID        string
	UserID           string
	AlternativePatch string
}

// ProvideAlternative allows user to provide their own fix instead of accepting proposed patch
func (s *SecurityService) ProvideAlternative(ctx context.Context, input ProvideAlternativeInput) (*domain.SecurityFinding, error) {
	finding, err := s.repo.GetSecurityFinding(ctx, input.FindingID)
	if err != nil {
		return nil, err
	}
	if finding == nil {
		return nil, fmt.Errorf("finding not found: %s", input.FindingID)
	}

	now := time.Now()
	finding.Status = domain.FindingUserAlternative
	finding.AlternativePatch = &input.AlternativePatch
	finding.ResolvedBy = input.UserID
	finding.ResolvedAt = &now

	if err := s.repo.UpdateSecurityFinding(ctx, finding); err != nil {
		return nil, err
	}

	return finding, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_ProvideAlternative`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add ProvideAlternative method

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Add CompleteSecurityReview Method

**Files:**
- Modify: `internal/service/security_service.go`
- Modify: `internal/service/security_service_test.go`

**Step 1: Write the test**

Add to `internal/service/security_service_test.go`:

```go
func TestSecurityService_CompleteSecurityReview(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	// Setup: create review and finding, then resolve finding
	reviewInput := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}
	review, _ := svc.StartSecurityReview(ctx, reviewInput)

	findingInput := CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityMedium,
		Location:      "src/api/users.ts:45",
		Description:   "Potential issue",
		ProposedPatch: "Fix it",
	}
	finding, _ := svc.CreateFinding(ctx, findingInput)
	svc.AcceptFinding(ctx, AcceptFindingInput{FindingID: finding.ID, UserID: "user-1"})

	// Complete review
	completed, err := svc.CompleteSecurityReview(ctx, review.ID)
	if err != nil {
		t.Fatalf("CompleteSecurityReview failed: %v", err)
	}

	if completed.Status != domain.ReviewCompleted {
		t.Errorf("got status %s, want completed", completed.Status)
	}
	if completed.CompletedAt == nil {
		t.Error("CompletedAt should be set")
	}
}

func TestSecurityService_CompleteSecurityReview_PendingFindings(t *testing.T) {
	ctx := context.Background()
	repo := repository.NewMockWorkflowRepository()
	svc := NewSecurityService(repo)

	// Setup: create review with unresolved finding
	reviewInput := StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	}
	review, _ := svc.StartSecurityReview(ctx, reviewInput)

	findingInput := CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "src/api/users.ts:45",
		Description:   "Critical issue",
		ProposedPatch: "Fix it",
	}
	svc.CreateFinding(ctx, findingInput) // Don't resolve

	// Try to complete - should fail
	_, err := svc.CompleteSecurityReview(ctx, review.ID)
	if err == nil {
		t.Fatal("CompleteSecurityReview should fail with pending findings")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_CompleteSecurityReview`

Expected: FAIL - method not defined

**Step 3: Write the implementation**

Add to `internal/service/security_service.go`:

```go
// CompleteSecurityReview marks a security review as completed
// Returns error if there are pending (unresolved) findings
func (s *SecurityService) CompleteSecurityReview(ctx context.Context, reviewID string) (*domain.SecurityReview, error) {
	review, err := s.repo.GetSecurityReview(ctx, reviewID)
	if err != nil {
		return nil, err
	}
	if review == nil {
		return nil, fmt.Errorf("review not found: %s", reviewID)
	}

	// Check for pending findings
	pending, err := s.repo.ListPendingSecurityFindings(ctx, review.ProjectID)
	if err != nil {
		return nil, err
	}
	if len(pending) > 0 {
		return nil, fmt.Errorf("cannot complete review: %d pending findings must be resolved", len(pending))
	}

	now := time.Now()
	review.Status = domain.ReviewCompleted
	review.CompletedAt = &now

	if err := s.repo.UpdateSecurityReview(ctx, review); err != nil {
		return nil, err
	}

	// Log event
	event := &domain.Event{
		ID:         uuid.New().String(),
		WorkflowID: review.WorkflowID,
		Type:       domain.EventSecurityReviewCompleted,
		ActorType:  "system",
		ActorID:    "security-agent",
		Data: map[string]any{
			"reviewId":      review.ID,
			"findingsCount": review.FindingsCount,
		},
		Timestamp: time.Now(),
	}
	_ = s.repo.AppendEvent(ctx, event)

	return review, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/service/... -v -run TestSecurityService_CompleteSecurityReview`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/security_service.go internal/service/security_service_test.go
git commit -m "$(cat <<'EOF'
feat(service): add CompleteSecurityReview method with pending check

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, `SecurityService` will have:

```go
type SecurityService struct { repo repository.WorkflowRepository }

func NewSecurityService(repo) *SecurityService
func (s *SecurityService) StartSecurityReview(ctx, input) (*SecurityReview, error)
func (s *SecurityService) CreateFinding(ctx, input) (*SecurityFinding, error)
func (s *SecurityService) AcceptFinding(ctx, input) (*SecurityFinding, error)
func (s *SecurityService) ProvideAlternative(ctx, input) (*SecurityFinding, error)
func (s *SecurityService) CompleteSecurityReview(ctx, reviewID) (*SecurityReview, error)
```

**Next:** Proceed to `04-security-agent.md`
