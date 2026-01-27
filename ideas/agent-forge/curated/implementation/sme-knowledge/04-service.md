# Task 6: Knowledge Service Layer

> **Navigation:** [Back to Overview](./00-overview.md) | Previous: [Repository](./03-repository.md) | Next: [API Handlers](./05-api-handlers.md)

---

## Task 6: Knowledge Service Layer

**Files:**
- Create: `internal/service/knowledge_service.go`
- Create: `internal/service/knowledge_service_test.go`

**Step 1: Write test for service**

Create `internal/service/knowledge_service_test.go`:
```go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func TestKnowledgeService_CreateGuideline(t *testing.T) {
	repo := memory.NewKnowledgeRepository()
	svc := NewKnowledgeService(repo)
	ctx := context.Background()

	input := CreateGuidelineInput{
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		Title:     "Error Handling",
		Category:  "error-handling",
		Content:   "All errors must be wrapped",
		Priority:  domain.PriorityMust,
		CreatedBy: "user1",
	}

	guideline, err := svc.CreateGuideline(ctx, input)
	if err != nil {
		t.Fatalf("CreateGuideline() error = %v", err)
	}

	if guideline.ID == "" {
		t.Error("ID should be generated")
	}
	if guideline.Title != input.Title {
		t.Errorf("Title = %v, want %v", guideline.Title, input.Title)
	}
	if guideline.Version != 1 {
		t.Errorf("Version = %v, want 1", guideline.Version)
	}
	if !guideline.Active {
		t.Error("Active should be true")
	}
}

func TestKnowledgeService_CreateGuideline_ValidationError(t *testing.T) {
	repo := memory.NewKnowledgeRepository()
	svc := NewKnowledgeService(repo)
	ctx := context.Background()

	input := CreateGuidelineInput{
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		// Missing Title
		Category: "error-handling",
		Content:  "All errors must be wrapped",
		Priority: domain.PriorityMust,
	}

	_, err := svc.CreateGuideline(ctx, input)
	if err == nil {
		t.Error("CreateGuideline() should fail with validation error")
	}
}

func TestKnowledgeService_UpdateGuideline(t *testing.T) {
	repo := memory.NewKnowledgeRepository()
	svc := NewKnowledgeService(repo)
	ctx := context.Background()

	// Create first
	input := CreateGuidelineInput{
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		Title:     "Original",
		Category:  "cat",
		Content:   "content",
		Priority:  domain.PriorityMust,
		CreatedBy: "user1",
	}
	created, _ := svc.CreateGuideline(ctx, input)

	// Update
	updateInput := UpdateGuidelineInput{
		ID:        created.ID,
		OrgID:     "org1",
		Title:     "Updated",
		Category:  "cat",
		Content:   "new content",
		Priority:  domain.PriorityShould,
		UpdatedBy: "user2",
	}

	updated, err := svc.UpdateGuideline(ctx, updateInput)
	if err != nil {
		t.Fatalf("UpdateGuideline() error = %v", err)
	}

	if updated.Title != "Updated" {
		t.Errorf("Title = %v, want Updated", updated.Title)
	}
	if updated.Version != 2 {
		t.Errorf("Version = %v, want 2", updated.Version)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -v`

Expected: FAIL - types not defined

**Step 3: Implement knowledge service**

Create `internal/service/knowledge_service.go`:
```go
package service

import (
	"context"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// KnowledgeService handles business logic for SME knowledge
type KnowledgeService struct {
	repo repository.KnowledgeRepository
}

// NewKnowledgeService creates a new service instance
func NewKnowledgeService(repo repository.KnowledgeRepository) *KnowledgeService {
	return &KnowledgeService{repo: repo}
}

// generateID creates a simple unique ID
func generateID() string {
	return time.Now().UnixNano()/1000000%1000000000 + "-" + randomString(8)
}

func randomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[time.Now().UnixNano()%int64(len(letters))]
		time.Sleep(time.Nanosecond)
	}
	return string(b)
}

// Guideline Operations

type CreateGuidelineInput struct {
	OrgID     string
	AgentType domain.AgentType
	Title     string
	Category  string
	Content   string
	Priority  domain.Priority
	CreatedBy string
}

func (s *KnowledgeService) CreateGuideline(ctx context.Context, input CreateGuidelineInput) (*domain.Guideline, error) {
	now := time.Now()

	guideline := &domain.Guideline{
		ID:        generateID(),
		OrgID:     input.OrgID,
		AgentType: input.AgentType,
		Title:     input.Title,
		Category:  input.Category,
		Content:   input.Content,
		Priority:  input.Priority,
		Active:    true,
		Version:   1,
		CreatedBy: input.CreatedBy,
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := guideline.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateGuideline(ctx, guideline); err != nil {
		return nil, err
	}

	return guideline, nil
}

func (s *KnowledgeService) GetGuideline(ctx context.Context, orgID, id string) (*domain.Guideline, error) {
	return s.repo.GetGuideline(ctx, orgID, id)
}

func (s *KnowledgeService) ListGuidelines(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Guideline, error) {
	return s.repo.ListGuidelines(ctx, orgID, agentType)
}

type UpdateGuidelineInput struct {
	ID        string
	OrgID     string
	Title     string
	Category  string
	Content   string
	Priority  domain.Priority
	UpdatedBy string
}

func (s *KnowledgeService) UpdateGuideline(ctx context.Context, input UpdateGuidelineInput) (*domain.Guideline, error) {
	existing, err := s.repo.GetGuideline(ctx, input.OrgID, input.ID)
	if err != nil {
		return nil, err
	}

	existing.Title = input.Title
	existing.Category = input.Category
	existing.Content = input.Content
	existing.Priority = input.Priority
	existing.Version++
	existing.UpdatedAt = time.Now()

	if err := existing.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.UpdateGuideline(ctx, existing); err != nil {
		return nil, err
	}

	return existing, nil
}

func (s *KnowledgeService) DeactivateGuideline(ctx context.Context, orgID, id string) error {
	return s.repo.DeactivateGuideline(ctx, orgID, id)
}

// Constraint Operations

type CreateConstraintInput struct {
	OrgID       string
	AgentType   domain.AgentType
	Name        string
	Description string
	Category    domain.ConstraintCategory
	Rule        string
	Severity    domain.Severity
	Examples    []domain.ConstraintViolationExample
	CreatedBy   string
}

func (s *KnowledgeService) CreateConstraint(ctx context.Context, input CreateConstraintInput) (*domain.Constraint, error) {
	now := time.Now()

	constraint := &domain.Constraint{
		ID:          generateID(),
		OrgID:       input.OrgID,
		AgentType:   input.AgentType,
		Name:        input.Name,
		Description: input.Description,
		Category:    input.Category,
		Rule:        input.Rule,
		Severity:    input.Severity,
		Examples:    input.Examples,
		Active:      true,
		Version:     1,
		CreatedBy:   input.CreatedBy,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := constraint.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateConstraint(ctx, constraint); err != nil {
		return nil, err
	}

	return constraint, nil
}

func (s *KnowledgeService) GetConstraint(ctx context.Context, orgID, id string) (*domain.Constraint, error) {
	return s.repo.GetConstraint(ctx, orgID, id)
}

func (s *KnowledgeService) ListConstraints(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Constraint, error) {
	return s.repo.ListConstraints(ctx, orgID, agentType)
}

type UpdateConstraintInput struct {
	ID          string
	OrgID       string
	Name        string
	Description string
	Category    domain.ConstraintCategory
	Rule        string
	Severity    domain.Severity
	Examples    []domain.ConstraintViolationExample
	UpdatedBy   string
}

func (s *KnowledgeService) UpdateConstraint(ctx context.Context, input UpdateConstraintInput) (*domain.Constraint, error) {
	existing, err := s.repo.GetConstraint(ctx, input.OrgID, input.ID)
	if err != nil {
		return nil, err
	}

	existing.Name = input.Name
	existing.Description = input.Description
	existing.Category = input.Category
	existing.Rule = input.Rule
	existing.Severity = input.Severity
	existing.Examples = input.Examples
	existing.Version++
	existing.UpdatedAt = time.Now()

	if err := existing.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.UpdateConstraint(ctx, existing); err != nil {
		return nil, err
	}

	return existing, nil
}

func (s *KnowledgeService) DeactivateConstraint(ctx context.Context, orgID, id string) error {
	return s.repo.DeactivateConstraint(ctx, orgID, id)
}

// Template Operations

type CreateTemplateInput struct {
	OrgID       string
	AgentType   domain.AgentType
	Name        string
	Description string
	Type        string
	Content     string
	Variables   []domain.TemplateVariable
	CreatedBy   string
}

func (s *KnowledgeService) CreateTemplate(ctx context.Context, input CreateTemplateInput) (*domain.Template, error) {
	now := time.Now()

	template := &domain.Template{
		ID:          generateID(),
		OrgID:       input.OrgID,
		AgentType:   input.AgentType,
		Name:        input.Name,
		Description: input.Description,
		Type:        input.Type,
		Content:     input.Content,
		Variables:   input.Variables,
		Active:      true,
		Version:     1,
		CreatedBy:   input.CreatedBy,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := template.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateTemplate(ctx, template); err != nil {
		return nil, err
	}

	return template, nil
}

func (s *KnowledgeService) GetTemplate(ctx context.Context, orgID, id string) (*domain.Template, error) {
	return s.repo.GetTemplate(ctx, orgID, id)
}

func (s *KnowledgeService) ListTemplates(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Template, error) {
	return s.repo.ListTemplates(ctx, orgID, agentType)
}

func (s *KnowledgeService) DeactivateTemplate(ctx context.Context, orgID, id string) error {
	return s.repo.DeactivateTemplate(ctx, orgID, id)
}

// Example Operations

type CreateExampleInput struct {
	OrgID       string
	AgentType   domain.AgentType
	Title       string
	Scenario    string
	GoodExample string
	BadExample  string
	Explanation string
	CreatedBy   string
}

func (s *KnowledgeService) CreateExample(ctx context.Context, input CreateExampleInput) (*domain.Example, error) {
	now := time.Now()

	example := &domain.Example{
		ID:          generateID(),
		OrgID:       input.OrgID,
		AgentType:   input.AgentType,
		Title:       input.Title,
		Scenario:    input.Scenario,
		GoodExample: input.GoodExample,
		BadExample:  input.BadExample,
		Explanation: input.Explanation,
		Active:      true,
		Version:     1,
		CreatedBy:   input.CreatedBy,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := example.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateExample(ctx, example); err != nil {
		return nil, err
	}

	return example, nil
}

func (s *KnowledgeService) GetExample(ctx context.Context, orgID, id string) (*domain.Example, error) {
	return s.repo.GetExample(ctx, orgID, id)
}

func (s *KnowledgeService) ListExamples(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Example, error) {
	return s.repo.ListExamples(ctx, orgID, agentType)
}

func (s *KnowledgeService) DeactivateExample(ctx context.Context, orgID, id string) error {
	return s.repo.DeactivateExample(ctx, orgID, id)
}
```

**Step 4: Run tests**

Run: `go test ./internal/service/... -v`

Expected: All PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add KnowledgeService with business logic"
```
