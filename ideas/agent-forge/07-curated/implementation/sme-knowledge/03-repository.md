# Task 5: In-Memory Repository Implementation

> **Navigation:** [Back to Overview](./00-overview.md) | Previous: [Domain Models](./02-domain-models.md) | Next: [Service Layer](./04-service.md)

---

## Task 5: In-Memory Repository Implementation

**Files:**
- Create: `internal/repository/memory/knowledge_repository.go`
- Create: `internal/repository/memory/knowledge_repository_test.go`

**Step 1: Write test for in-memory repository**

Create `internal/repository/memory/knowledge_repository_test.go`:
```go
package memory

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

func TestMemoryKnowledgeRepository_CreateAndGetGuideline(t *testing.T) {
	repo := NewKnowledgeRepository()
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
		Version:   1,
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
		t.Errorf("Title = %v, want %v", got.Title, guideline.Title)
	}

	// Get wrong org
	_, err = repo.GetGuideline(ctx, "org2", "g1")
	if err != repository.ErrNotFound {
		t.Errorf("GetGuideline() wrong org error = %v, want ErrNotFound", err)
	}

	// Get non-existent
	_, err = repo.GetGuideline(ctx, "org1", "nonexistent")
	if err != repository.ErrNotFound {
		t.Errorf("GetGuideline() non-existent error = %v, want ErrNotFound", err)
	}
}

func TestMemoryKnowledgeRepository_ListGuidelines(t *testing.T) {
	repo := NewKnowledgeRepository()
	ctx := context.Background()

	// Create guidelines for different agents
	guidelines := []*domain.Guideline{
		{ID: "g1", OrgID: "org1", AgentType: domain.AgentCoding, Title: "G1", Category: "cat", Content: "c", Priority: domain.PriorityMust, Active: true},
		{ID: "g2", OrgID: "org1", AgentType: domain.AgentCoding, Title: "G2", Category: "cat", Content: "c", Priority: domain.PriorityMust, Active: true},
		{ID: "g3", OrgID: "org1", AgentType: domain.AgentArchitecture, Title: "G3", Category: "cat", Content: "c", Priority: domain.PriorityMust, Active: true},
		{ID: "g4", OrgID: "org2", AgentType: domain.AgentCoding, Title: "G4", Category: "cat", Content: "c", Priority: domain.PriorityMust, Active: true},
	}

	for _, g := range guidelines {
		if err := repo.CreateGuideline(ctx, g); err != nil {
			t.Fatalf("CreateGuideline() error = %v", err)
		}
	}

	// List for org1, coding agent
	list, err := repo.ListGuidelines(ctx, "org1", domain.AgentCoding)
	if err != nil {
		t.Fatalf("ListGuidelines() error = %v", err)
	}
	if len(list) != 2 {
		t.Errorf("ListGuidelines() len = %v, want 2", len(list))
	}

	// List for org1, architecture agent
	list, err = repo.ListGuidelines(ctx, "org1", domain.AgentArchitecture)
	if err != nil {
		t.Fatalf("ListGuidelines() error = %v", err)
	}
	if len(list) != 1 {
		t.Errorf("ListGuidelines() len = %v, want 1", len(list))
	}
}

func TestMemoryKnowledgeRepository_UpdateGuideline(t *testing.T) {
	repo := NewKnowledgeRepository()
	ctx := context.Background()

	guideline := &domain.Guideline{
		ID:        "g1",
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		Title:     "Original",
		Category:  "cat",
		Content:   "c",
		Priority:  domain.PriorityMust,
		Active:    true,
		Version:   1,
	}

	if err := repo.CreateGuideline(ctx, guideline); err != nil {
		t.Fatalf("CreateGuideline() error = %v", err)
	}

	// Update
	guideline.Title = "Updated"
	guideline.Version = 2
	if err := repo.UpdateGuideline(ctx, guideline); err != nil {
		t.Fatalf("UpdateGuideline() error = %v", err)
	}

	// Verify
	got, _ := repo.GetGuideline(ctx, "org1", "g1")
	if got.Title != "Updated" {
		t.Errorf("Title = %v, want Updated", got.Title)
	}
	if got.Version != 2 {
		t.Errorf("Version = %v, want 2", got.Version)
	}
}

func TestMemoryKnowledgeRepository_DeactivateGuideline(t *testing.T) {
	repo := NewKnowledgeRepository()
	ctx := context.Background()

	guideline := &domain.Guideline{
		ID:        "g1",
		OrgID:     "org1",
		AgentType: domain.AgentCoding,
		Title:     "G1",
		Category:  "cat",
		Content:   "c",
		Priority:  domain.PriorityMust,
		Active:    true,
	}

	if err := repo.CreateGuideline(ctx, guideline); err != nil {
		t.Fatalf("CreateGuideline() error = %v", err)
	}

	// Deactivate
	if err := repo.DeactivateGuideline(ctx, "org1", "g1"); err != nil {
		t.Fatalf("DeactivateGuideline() error = %v", err)
	}

	// Verify not in list
	list, _ := repo.ListGuidelines(ctx, "org1", domain.AgentCoding)
	if len(list) != 0 {
		t.Errorf("ListGuidelines() after deactivate len = %v, want 0", len(list))
	}

	// But still gettable
	got, _ := repo.GetGuideline(ctx, "org1", "g1")
	if got.Active != false {
		t.Errorf("Active = %v, want false", got.Active)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -v`

Expected: FAIL - NewKnowledgeRepository not defined

**Step 3: Implement in-memory repository**

Create `internal/repository/memory/knowledge_repository.go`:
```go
package memory

import (
	"context"
	"sync"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// KnowledgeRepository is an in-memory implementation for testing/development
type KnowledgeRepository struct {
	mu          sync.RWMutex
	guidelines  map[string]*domain.Guideline
	templates   map[string]*domain.Template
	examples    map[string]*domain.Example
	constraints map[string]*domain.Constraint
}

// NewKnowledgeRepository creates a new in-memory repository
func NewKnowledgeRepository() *KnowledgeRepository {
	return &KnowledgeRepository{
		guidelines:  make(map[string]*domain.Guideline),
		templates:   make(map[string]*domain.Template),
		examples:    make(map[string]*domain.Example),
		constraints: make(map[string]*domain.Constraint),
	}
}

// Guidelines

func (r *KnowledgeRepository) CreateGuideline(ctx context.Context, g *domain.Guideline) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := g.OrgID + "/" + g.ID
	if _, exists := r.guidelines[key]; exists {
		return repository.ErrAlreadyExists
	}

	// Store a copy
	copy := *g
	r.guidelines[key] = &copy
	return nil
}

func (r *KnowledgeRepository) GetGuideline(ctx context.Context, orgID, id string) (*domain.Guideline, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := orgID + "/" + id
	g, exists := r.guidelines[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	// Return a copy
	copy := *g
	return &copy, nil
}

func (r *KnowledgeRepository) ListGuidelines(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Guideline, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Guideline
	for _, g := range r.guidelines {
		if g.OrgID == orgID && g.AgentType == agentType && g.Active {
			copy := *g
			result = append(result, &copy)
		}
	}
	return result, nil
}

func (r *KnowledgeRepository) UpdateGuideline(ctx context.Context, g *domain.Guideline) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := g.OrgID + "/" + g.ID
	if _, exists := r.guidelines[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *g
	r.guidelines[key] = &copy
	return nil
}

func (r *KnowledgeRepository) DeactivateGuideline(ctx context.Context, orgID, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := orgID + "/" + id
	g, exists := r.guidelines[key]
	if !exists {
		return repository.ErrNotFound
	}

	g.Active = false
	return nil
}

// Templates

func (r *KnowledgeRepository) CreateTemplate(ctx context.Context, t *domain.Template) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := t.OrgID + "/" + t.ID
	if _, exists := r.templates[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *t
	r.templates[key] = &copy
	return nil
}

func (r *KnowledgeRepository) GetTemplate(ctx context.Context, orgID, id string) (*domain.Template, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := orgID + "/" + id
	t, exists := r.templates[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *t
	return &copy, nil
}

func (r *KnowledgeRepository) ListTemplates(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Template, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Template
	for _, t := range r.templates {
		if t.OrgID == orgID && t.AgentType == agentType && t.Active {
			copy := *t
			result = append(result, &copy)
		}
	}
	return result, nil
}

func (r *KnowledgeRepository) UpdateTemplate(ctx context.Context, t *domain.Template) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := t.OrgID + "/" + t.ID
	if _, exists := r.templates[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *t
	r.templates[key] = &copy
	return nil
}

func (r *KnowledgeRepository) DeactivateTemplate(ctx context.Context, orgID, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := orgID + "/" + id
	t, exists := r.templates[key]
	if !exists {
		return repository.ErrNotFound
	}

	t.Active = false
	return nil
}

// Examples

func (r *KnowledgeRepository) CreateExample(ctx context.Context, e *domain.Example) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := e.OrgID + "/" + e.ID
	if _, exists := r.examples[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *e
	r.examples[key] = &copy
	return nil
}

func (r *KnowledgeRepository) GetExample(ctx context.Context, orgID, id string) (*domain.Example, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := orgID + "/" + id
	e, exists := r.examples[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *e
	return &copy, nil
}

func (r *KnowledgeRepository) ListExamples(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Example, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Example
	for _, e := range r.examples {
		if e.OrgID == orgID && e.AgentType == agentType && e.Active {
			copy := *e
			result = append(result, &copy)
		}
	}
	return result, nil
}

func (r *KnowledgeRepository) UpdateExample(ctx context.Context, e *domain.Example) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := e.OrgID + "/" + e.ID
	if _, exists := r.examples[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *e
	r.examples[key] = &copy
	return nil
}

func (r *KnowledgeRepository) DeactivateExample(ctx context.Context, orgID, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := orgID + "/" + id
	e, exists := r.examples[key]
	if !exists {
		return repository.ErrNotFound
	}

	e.Active = false
	return nil
}

// Constraints

func (r *KnowledgeRepository) CreateConstraint(ctx context.Context, c *domain.Constraint) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := c.OrgID + "/" + c.ID
	if _, exists := r.constraints[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *c
	r.constraints[key] = &copy
	return nil
}

func (r *KnowledgeRepository) GetConstraint(ctx context.Context, orgID, id string) (*domain.Constraint, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := orgID + "/" + id
	c, exists := r.constraints[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *c
	return &copy, nil
}

func (r *KnowledgeRepository) ListConstraints(ctx context.Context, orgID string, agentType domain.AgentType) ([]*domain.Constraint, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Constraint
	for _, c := range r.constraints {
		if c.OrgID == orgID && c.AgentType == agentType && c.Active {
			copy := *c
			result = append(result, &copy)
		}
	}
	return result, nil
}

func (r *KnowledgeRepository) UpdateConstraint(ctx context.Context, c *domain.Constraint) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := c.OrgID + "/" + c.ID
	if _, exists := r.constraints[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *c
	r.constraints[key] = &copy
	return nil
}

func (r *KnowledgeRepository) DeactivateConstraint(ctx context.Context, orgID, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := orgID + "/" + id
	c, exists := r.constraints[key]
	if !exists {
		return repository.ErrNotFound
	}

	c.Active = false
	return nil
}

// Ensure interface compliance
var _ repository.KnowledgeRepository = (*KnowledgeRepository)(nil)
```

**Step 4: Run tests**

Run: `go test ./internal/repository/memory/... -v`

Expected: All PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add in-memory KnowledgeRepository implementation"
```
