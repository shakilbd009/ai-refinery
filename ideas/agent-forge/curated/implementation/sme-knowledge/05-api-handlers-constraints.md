# Task 8: Constraints API Handler

> **Navigation:** [Back to API Handlers](./05-api-handlers.md) | [Back to Overview](./00-overview.md)

---

## Task 8: Constraints API Handler

**Files:**
- Create: `internal/api/handlers/constraints.go`
- Create: `internal/api/handlers/constraints_test.go`

**Step 1: Write test for constraints handler**

Create `internal/api/handlers/constraints_test.go`:
```go
package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/service"
)

func setupConstraintsHandler() (*ConstraintsHandler, *chi.Mux) {
	repo := memory.NewKnowledgeRepository()
	svc := service.NewKnowledgeService(repo)
	handler := NewConstraintsHandler(svc)

	r := chi.NewRouter()
	r.Route("/api/v1/orgs/{orgID}/knowledge/{agentType}/constraints", func(r chi.Router) {
		r.Post("/", handler.Create)
		r.Get("/", handler.List)
		r.Get("/{id}", handler.Get)
		r.Delete("/{id}", handler.Deactivate)
	})

	return handler, r
}

func TestConstraintsHandler_Create(t *testing.T) {
	_, router := setupConstraintsHandler()

	body := map[string]interface{}{
		"name":        "No console.log",
		"description": "Disallow console.log in production code",
		"category":    "blocklist",
		"rule":        "Code must not contain console.log",
		"severity":    "error",
		"examples": []map[string]string{
			{"violation": "console.log('debug')", "explanation": "Use Logger instead"},
		},
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/api/v1/orgs/org1/knowledge/coding/constraints", bytes.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "user1")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %v, want %v. Body: %s", w.Code, http.StatusCreated, w.Body.String())
	}

	var response domain.Constraint
	json.Unmarshal(w.Body.Bytes(), &response)

	if response.ID == "" {
		t.Error("ID should be set")
	}
	if response.Name != "No console.log" {
		t.Errorf("Name = %v, want No console.log", response.Name)
	}
	if len(response.Examples) != 1 {
		t.Errorf("Examples len = %v, want 1", len(response.Examples))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -v -run TestConstraints`

Expected: FAIL - types not defined

**Step 3: Implement constraints handler**

Create `internal/api/handlers/constraints.go`:
```go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

type ConstraintsHandler struct {
	svc *service.KnowledgeService
}

func NewConstraintsHandler(svc *service.KnowledgeService) *ConstraintsHandler {
	return &ConstraintsHandler{svc: svc}
}

type CreateConstraintRequest struct {
	Name        string                             `json:"name"`
	Description string                             `json:"description"`
	Category    domain.ConstraintCategory          `json:"category"`
	Rule        string                             `json:"rule"`
	Severity    domain.Severity                    `json:"severity"`
	Examples    []domain.ConstraintViolationExample `json:"examples"`
}

func (h *ConstraintsHandler) Create(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")
	userID := r.Header.Get("X-User-ID")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	var req CreateConstraintRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.CreateConstraintInput{
		OrgID:       orgID,
		AgentType:   agentType,
		Name:        req.Name,
		Description: req.Description,
		Category:    req.Category,
		Rule:        req.Rule,
		Severity:    req.Severity,
		Examples:    req.Examples,
		CreatedBy:   userID,
	}

	constraint, err := h.svc.CreateConstraint(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(constraint)
}

func (h *ConstraintsHandler) Get(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	constraint, err := h.svc.GetConstraint(r.Context(), orgID, id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(constraint)
}

func (h *ConstraintsHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	constraints, err := h.svc.ListConstraints(r.Context(), orgID, agentType)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if constraints == nil {
		constraints = []*domain.Constraint{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(constraints)
}

func (h *ConstraintsHandler) Deactivate(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	err := h.svc.DeactivateConstraint(r.Context(), orgID, id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
```

**Step 4: Run tests**

Run: `go test ./internal/api/handlers/... -v`

Expected: All PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Constraints API handler"
```
