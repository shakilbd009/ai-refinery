# Tasks 3-4: Domain Models and Repository Interface

> **Navigation:** [Back to Overview](./00-overview.md) | Previous: [Setup Router](./01-setup-router.md) | Next: [Repository](./03-repository.md)

---

## Task 3: SME Knowledge Domain Models

**Files:**
- Create: `internal/domain/knowledge.go`
- Create: `internal/domain/knowledge_test.go`

**Step 1: Write test for Guideline validation**

Create `internal/domain/knowledge_test.go`:
```go
package domain

import (
	"testing"
)

func TestGuideline_Validate(t *testing.T) {
	tests := []struct {
		name      string
		guideline Guideline
		wantErr   bool
	}{
		{
			name: "valid guideline",
			guideline: Guideline{
				Title:    "Error Handling",
				Category: "error-handling",
				Content:  "All errors must be wrapped",
				Priority: PriorityMust,
			},
			wantErr: false,
		},
		{
			name: "missing title",
			guideline: Guideline{
				Category: "error-handling",
				Content:  "All errors must be wrapped",
				Priority: PriorityMust,
			},
			wantErr: true,
		},
		{
			name: "invalid priority",
			guideline: Guideline{
				Title:    "Error Handling",
				Category: "error-handling",
				Content:  "All errors must be wrapped",
				Priority: "invalid",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.guideline.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -v`

Expected: FAIL - types not defined

**Step 3: Create domain models**

Create `internal/domain/knowledge.go`:
```go
package domain

import (
	"errors"
	"time"
)

// Priority levels for guidelines
type Priority string

const (
	PriorityMust   Priority = "must"
	PriorityShould Priority = "should"
	PriorityMay    Priority = "may"
)

func (p Priority) IsValid() bool {
	switch p {
	case PriorityMust, PriorityShould, PriorityMay:
		return true
	}
	return false
}

// Severity levels for constraints
type Severity string

const (
	SeverityError   Severity = "error"
	SeverityWarning Severity = "warning"
)

func (s Severity) IsValid() bool {
	switch s {
	case SeverityError, SeverityWarning:
		return true
	}
	return false
}

// ConstraintCategory types
type ConstraintCategory string

const (
	CategoryAllowlist ConstraintCategory = "allowlist"
	CategoryBlocklist ConstraintCategory = "blocklist"
	CategoryQuality   ConstraintCategory = "quality"
	CategorySecurity  ConstraintCategory = "security"
)

func (c ConstraintCategory) IsValid() bool {
	switch c {
	case CategoryAllowlist, CategoryBlocklist, CategoryQuality, CategorySecurity:
		return true
	}
	return false
}

// AgentType defines which agent the knowledge applies to
type AgentType string

const (
	AgentRequirements AgentType = "requirements"
	AgentArchitecture AgentType = "architecture"
	AgentCoding       AgentType = "coding"
	AgentSecurity     AgentType = "security"
)

func (a AgentType) IsValid() bool {
	switch a {
	case AgentRequirements, AgentArchitecture, AgentCoding, AgentSecurity:
		return true
	}
	return false
}

// Guideline represents a prose standard or principle
type Guideline struct {
	ID        string    `json:"id" firestore:"id"`
	OrgID     string    `json:"orgId" firestore:"orgId"`
	AgentType AgentType `json:"agentType" firestore:"agentType"`
	Title     string    `json:"title" firestore:"title"`
	Category  string    `json:"category" firestore:"category"`
	Content   string    `json:"content" firestore:"content"`
	Priority  Priority  `json:"priority" firestore:"priority"`
	Active    bool      `json:"active" firestore:"active"`
	Version   int       `json:"version" firestore:"version"`
	CreatedBy string    `json:"createdBy" firestore:"createdBy"`
	CreatedAt time.Time `json:"createdAt" firestore:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" firestore:"updatedAt"`
}

func (g *Guideline) Validate() error {
	if g.Title == "" {
		return errors.New("title is required")
	}
	if g.Category == "" {
		return errors.New("category is required")
	}
	if g.Content == "" {
		return errors.New("content is required")
	}
	if !g.Priority.IsValid() {
		return errors.New("invalid priority")
	}
	return nil
}

// TemplateVariable represents a variable in a template
type TemplateVariable struct {
	Name         string `json:"name" firestore:"name"`
	Description  string `json:"description" firestore:"description"`
	DefaultValue string `json:"defaultValue" firestore:"defaultValue"`
}

// Template represents boilerplate structures
type Template struct {
	ID          string             `json:"id" firestore:"id"`
	OrgID       string             `json:"orgId" firestore:"orgId"`
	AgentType   AgentType          `json:"agentType" firestore:"agentType"`
	Name        string             `json:"name" firestore:"name"`
	Description string             `json:"description" firestore:"description"`
	Type        string             `json:"type" firestore:"type"`
	Content     string             `json:"content" firestore:"content"`
	Variables   []TemplateVariable `json:"variables" firestore:"variables"`
	Active      bool               `json:"active" firestore:"active"`
	Version     int                `json:"version" firestore:"version"`
	CreatedBy   string             `json:"createdBy" firestore:"createdBy"`
	CreatedAt   time.Time          `json:"createdAt" firestore:"createdAt"`
	UpdatedAt   time.Time          `json:"updatedAt" firestore:"updatedAt"`
}

func (t *Template) Validate() error {
	if t.Name == "" {
		return errors.New("name is required")
	}
	if t.Type == "" {
		return errors.New("type is required")
	}
	if t.Content == "" {
		return errors.New("content is required")
	}
	return nil
}

// Example represents good/bad reference implementations
type Example struct {
	ID          string    `json:"id" firestore:"id"`
	OrgID       string    `json:"orgId" firestore:"orgId"`
	AgentType   AgentType `json:"agentType" firestore:"agentType"`
	Title       string    `json:"title" firestore:"title"`
	Scenario    string    `json:"scenario" firestore:"scenario"`
	GoodExample string    `json:"goodExample" firestore:"goodExample"`
	BadExample  string    `json:"badExample" firestore:"badExample"`
	Explanation string    `json:"explanation" firestore:"explanation"`
	Active      bool      `json:"active" firestore:"active"`
	Version     int       `json:"version" firestore:"version"`
	CreatedBy   string    `json:"createdBy" firestore:"createdBy"`
	CreatedAt   time.Time `json:"createdAt" firestore:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt" firestore:"updatedAt"`
}

func (e *Example) Validate() error {
	if e.Title == "" {
		return errors.New("title is required")
	}
	if e.Scenario == "" {
		return errors.New("scenario is required")
	}
	if e.GoodExample == "" {
		return errors.New("goodExample is required")
	}
	if e.Explanation == "" {
		return errors.New("explanation is required")
	}
	return nil
}

// ConstraintViolationExample helps LLM-judge understand violations
type ConstraintViolationExample struct {
	Violation   string `json:"violation" firestore:"violation"`
	Explanation string `json:"explanation" firestore:"explanation"`
}

// Constraint represents hard rules enforced by LLM-judge
type Constraint struct {
	ID          string                       `json:"id" firestore:"id"`
	OrgID       string                       `json:"orgId" firestore:"orgId"`
	AgentType   AgentType                    `json:"agentType" firestore:"agentType"`
	Name        string                       `json:"name" firestore:"name"`
	Description string                       `json:"description" firestore:"description"`
	Category    ConstraintCategory           `json:"category" firestore:"category"`
	Rule        string                       `json:"rule" firestore:"rule"`
	Severity    Severity                     `json:"severity" firestore:"severity"`
	Examples    []ConstraintViolationExample `json:"examples" firestore:"examples"`
	Active      bool                         `json:"active" firestore:"active"`
	Version     int                          `json:"version" firestore:"version"`
	CreatedBy   string                       `json:"createdBy" firestore:"createdBy"`
	CreatedAt   time.Time                    `json:"createdAt" firestore:"createdAt"`
	UpdatedAt   time.Time                    `json:"updatedAt" firestore:"updatedAt"`
}

func (c *Constraint) Validate() error {
	if c.Name == "" {
		return errors.New("name is required")
	}
	if c.Rule == "" {
		return errors.New("rule is required")
	}
	if !c.Category.IsValid() {
		return errors.New("invalid category")
	}
	if !c.Severity.IsValid() {
		return errors.New("invalid severity")
	}
	return nil
}
```

**Step 4: Run tests to verify they pass**

Run: `go test ./internal/domain/... -v`

Expected: PASS

**Step 5: Add more validation tests**

Add to `internal/domain/knowledge_test.go`:
```go
func TestConstraint_Validate(t *testing.T) {
	tests := []struct {
		name       string
		constraint Constraint
		wantErr    bool
	}{
		{
			name: "valid constraint",
			constraint: Constraint{
				Name:     "No console.log",
				Rule:     "Code must not contain console.log",
				Category: CategoryBlocklist,
				Severity: SeverityError,
			},
			wantErr: false,
		},
		{
			name: "missing name",
			constraint: Constraint{
				Rule:     "Code must not contain console.log",
				Category: CategoryBlocklist,
				Severity: SeverityError,
			},
			wantErr: true,
		},
		{
			name: "invalid category",
			constraint: Constraint{
				Name:     "No console.log",
				Rule:     "Code must not contain console.log",
				Category: "invalid",
				Severity: SeverityError,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.constraint.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestAgentType_IsValid(t *testing.T) {
	tests := []struct {
		agentType AgentType
		want      bool
	}{
		{AgentRequirements, true},
		{AgentArchitecture, true},
		{AgentCoding, true},
		{AgentSecurity, true},
		{"invalid", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(string(tt.agentType), func(t *testing.T) {
			if got := tt.agentType.IsValid(); got != tt.want {
				t.Errorf("IsValid() = %v, want %v", got, tt.want)
			}
		})
	}
}
```

**Step 6: Run all tests**

Run: `go test ./internal/domain/... -v`

Expected: All PASS

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add SME Knowledge domain models with validation"
```

---

## Task 4: Repository Interface

**Files:**
- Create: `internal/repository/knowledge_repository.go`
- Create: `internal/repository/knowledge_repository_test.go`

**Step 1: Write test for repository interface**

Create `internal/repository/knowledge_repository_test.go`:
```go
package repository

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// MockKnowledgeRepository for testing
type MockKnowledgeRepository struct {
	guidelines  map[string]*domain.Guideline
	constraints map[string]*domain.Constraint
	templates   map[string]*domain.Template
	examples    map[string]*domain.Example
}

func NewMockKnowledgeRepository() *MockKnowledgeRepository {
	return &MockKnowledgeRepository{
		guidelines:  make(map[string]*domain.Guideline),
		constraints: make(map[string]*domain.Constraint),
		templates:   make(map[string]*domain.Template),
		examples:    make(map[string]*domain.Example),
	}
}

func (m *MockKnowledgeRepository) CreateGuideline(ctx context.Context, g *domain.Guideline) error {
	m.guidelines[g.ID] = g
	return nil
}

func (m *MockKnowledgeRepository) GetGuideline(ctx context.Context, orgID, id string) (*domain.Guideline, error) {
	g, ok := m.guidelines[id]
	if !ok || g.OrgID != orgID {
		return nil, ErrNotFound
	}
	return g, nil
}

func (m *MockKnowledgeRepository) ListGuidelines(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Guideline, error) {
	var result []*domain.Guideline
	for _, g := range m.guidelines {
		if g.OrgID == orgID && g.AgentType == agentType && g.Active {
			result = append(result, g)
		}
	}
	return result, nil
}

func (m *MockKnowledgeRepository) UpdateGuideline(ctx context.Context, g *domain.Guideline) error {
	if _, ok := m.guidelines[g.ID]; !ok {
		return ErrNotFound
	}
	m.guidelines[g.ID] = g
	return nil
}

func (m *MockKnowledgeRepository) DeactivateGuideline(ctx context.Context, orgID, id string) error {
	g, ok := m.guidelines[id]
	if !ok || g.OrgID != orgID {
		return ErrNotFound
	}
	g.Active = false
	return nil
}

func TestMockKnowledgeRepository_Guideline(t *testing.T) {
	repo := NewMockKnowledgeRepository()
	ctx := context.Background()

	guideline := &domain.Guideline{
		ID:        "g1",
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		Title:     "Error Handling",
		Category:  "error-handling",
		Content:   "All errors must be wrapped",
		Priority:  domain.PriorityMust,
		Active:    true,
	}

	// Create
	err := repo.CreateGuideline(ctx, guideline)
	if err != nil {
		t.Fatalf("CreateGuideline() error = %v", err)
	}

	// Get
	got, err := repo.GetGuideline(ctx, "org1", "g1")
	if err != nil {
		t.Fatalf("GetGuideline() error = %v", err)
	}
	if got.Title != guideline.Title {
		t.Errorf("GetGuideline() Title = %v, want %v", got.Title, guideline.Title)
	}

	// List
	list, err := repo.ListGuidelines(ctx, "org1", domain.AgentCoding)
	if err != nil {
		t.Fatalf("ListGuidelines() error = %v", err)
	}
	if len(list) != 1 {
		t.Errorf("ListGuidelines() len = %v, want 1", len(list))
	}

	// Deactivate
	err = repo.DeactivateGuideline(ctx, "org1", "g1")
	if err != nil {
		t.Fatalf("DeactivateGuideline() error = %v", err)
	}

	// List after deactivate should be empty
	list, err = repo.ListGuidelines(ctx, "org1", domain.AgentCoding)
	if err != nil {
		t.Fatalf("ListGuidelines() error = %v", err)
	}
	if len(list) != 0 {
		t.Errorf("ListGuidelines() after deactivate len = %v, want 0", len(list))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/... -v`

Expected: FAIL - ErrNotFound not defined

**Step 3: Create repository interface**

Create `internal/repository/knowledge_repository.go`:
```go
package repository

import (
	"context"
	"errors"

	"github.com/anthropics/agentic-platform/internal/domain"
)

var (
	ErrNotFound      = errors.New("not found")
	ErrAlreadyExists = errors.New("already exists")
)

// KnowledgeRepository defines the interface for SME knowledge storage
type KnowledgeRepository interface {
	// Guidelines
	CreateGuideline(ctx context.Context, g *domain.Guideline) error
	GetGuideline(ctx context.Context, orgID, id string) (*domain.Guideline, error)
	ListGuidelines(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Guideline, error)
	UpdateGuideline(ctx context.Context, g *domain.Guideline) error
	DeactivateGuideline(ctx context.Context, orgID, id string) error

	// Templates
	CreateTemplate(ctx context.Context, t *domain.Template) error
	GetTemplate(ctx context.Context, orgID, id string) (*domain.Template, error)
	ListTemplates(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Template, error)
	UpdateTemplate(ctx context.Context, t *domain.Template) error
	DeactivateTemplate(ctx context.Context, orgID, id string) error

	// Examples
	CreateExample(ctx context.Context, e *domain.Example) error
	GetExample(ctx context.Context, orgID, id string) (*domain.Example, error)
	ListExamples(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Example, error)
	UpdateExample(ctx context.Context, e *domain.Example) error
	DeactivateExample(ctx context.Context, orgID, id string) error

	// Constraints
	CreateConstraint(ctx context.Context, c *domain.Constraint) error
	GetConstraint(ctx context.Context, orgID, id string) (*domain.Constraint, error)
	ListConstraints(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Constraint, error)
	UpdateConstraint(ctx context.Context, c *domain.Constraint) error
	DeactivateConstraint(ctx context.Context, orgID, id string) error
}
```

**Step 4: Run tests**

Run: `go test ./internal/repository/... -v`

Expected: PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add KnowledgeRepository interface with mock implementation"
```
