# Tasks 7-10: API Handlers

> **Navigation:** [Back to Overview](./00-overview.md) | Previous: [Service Layer](./04-service.md)

---

## Task 7: Guidelines API Handler

**Files:**
- Create: `internal/api/handlers/guidelines.go`
- Create: `internal/api/handlers/guidelines_test.go`
- Modify: `internal/api/routes/routes.go`

**Step 1: Write test for guidelines handler**

Create `internal/api/handlers/guidelines_test.go`:
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

func setupGuidelinesHandler() (*GuidelinesHandler, *chi.Mux) {
	repo := memory.NewKnowledgeRepository()
	svc := service.NewKnowledgeService(repo)
	handler := NewGuidelinesHandler(svc)

	r := chi.NewRouter()
	r.Route("/api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines", func(r chi.Router) {
		r.Post("/", handler.Create)
		r.Get("/", handler.List)
		r.Get("/{id}", handler.Get)
		r.Put("/{id}", handler.Update)
		r.Delete("/{id}", handler.Deactivate)
	})

	return handler, r
}

func TestGuidelinesHandler_Create(t *testing.T) {
	_, router := setupGuidelinesHandler()

	body := map[string]interface{}{
		"title":    "Error Handling",
		"category": "error-handling",
		"content":  "All errors must be wrapped",
		"priority": "must",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/api/v1/orgs/org1/knowledge/coding/guidelines", bytes.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "user1")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %v, want %v. Body: %s", w.Code, http.StatusCreated, w.Body.String())
	}

	var response domain.Guideline
	json.Unmarshal(w.Body.Bytes(), &response)

	if response.ID == "" {
		t.Error("ID should be set")
	}
	if response.Title != "Error Handling" {
		t.Errorf("Title = %v, want Error Handling", response.Title)
	}
}

func TestGuidelinesHandler_List(t *testing.T) {
	_, router := setupGuidelinesHandler()

	// Create a guideline first
	body := map[string]interface{}{
		"title":    "G1",
		"category": "cat",
		"content":  "content",
		"priority": "must",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/api/v1/orgs/org1/knowledge/coding/guidelines", bytes.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "user1")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Now list
	req = httptest.NewRequest("GET", "/api/v1/orgs/org1/knowledge/coding/guidelines", nil)
	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %v, want %v", w.Code, http.StatusOK)
	}

	var response []*domain.Guideline
	json.Unmarshal(w.Body.Bytes(), &response)

	if len(response) != 1 {
		t.Errorf("len = %v, want 1", len(response))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -v`

Expected: FAIL - types not defined

**Step 3: Implement guidelines handler**

Create `internal/api/handlers/guidelines.go`:
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

type GuidelinesHandler struct {
	svc *service.KnowledgeService
}

func NewGuidelinesHandler(svc *service.KnowledgeService) *GuidelinesHandler {
	return &GuidelinesHandler{svc: svc}
}

type CreateGuidelineRequest struct {
	Title    string          `json:"title"`
	Category string          `json:"category"`
	Content  string          `json:"content"`
	Priority domain.Priority `json:"priority"`
}

func (h *GuidelinesHandler) Create(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")
	userID := r.Header.Get("X-User-ID")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	var req CreateGuidelineRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.CreateGuidelineInput{
		OrgID:     orgID,
		AgentType: agentType,
		Title:     req.Title,
		Category:  req.Category,
		Content:   req.Content,
		Priority:  req.Priority,
		CreatedBy: userID,
	}

	guideline, err := h.svc.CreateGuideline(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(guideline)
}

func (h *GuidelinesHandler) Get(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	guideline, err := h.svc.GetGuideline(r.Context(), orgID, id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(guideline)
}

func (h *GuidelinesHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	guidelines, err := h.svc.ListGuidelines(r.Context(), orgID, agentType)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if guidelines == nil {
		guidelines = []*domain.Guideline{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(guidelines)
}

type UpdateGuidelineRequest struct {
	Title    string          `json:"title"`
	Category string          `json:"category"`
	Content  string          `json:"content"`
	Priority domain.Priority `json:"priority"`
}

func (h *GuidelinesHandler) Update(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")
	userID := r.Header.Get("X-User-ID")

	var req UpdateGuidelineRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.UpdateGuidelineInput{
		ID:        id,
		OrgID:     orgID,
		Title:     req.Title,
		Category:  req.Category,
		Content:   req.Content,
		Priority:  req.Priority,
		UpdatedBy: userID,
	}

	guideline, err := h.svc.UpdateGuideline(r.Context(), input)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(guideline)
}

func (h *GuidelinesHandler) Deactivate(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	err := h.svc.DeactivateGuideline(r.Context(), orgID, id)
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
git commit -m "feat: add Guidelines API handler"
```

---

## Task 8: Constraints API Handler

**Files:**
- Create: `internal/api/handlers/constraints.go`
- Create: `internal/api/handlers/constraints_test.go`

See [05-api-handlers-constraints.md](./05-api-handlers-constraints.md) for the full implementation.

---

## Task 9: Wire Up Routes and Main

**Files:**
- Modify: `internal/api/routes/routes.go`
- Modify: `cmd/api/main.go`

See [05-api-handlers-routes.md](./05-api-handlers-routes.md) for the full implementation.

---

## Task 10: Add Templates and Examples Handlers

**Files:**
- Create: `internal/api/handlers/templates.go`
- Create: `internal/api/handlers/examples.go`
- Modify: `internal/api/routes/routes.go`

See [05-api-handlers-templates.md](./05-api-handlers-templates.md) for the full implementation.
