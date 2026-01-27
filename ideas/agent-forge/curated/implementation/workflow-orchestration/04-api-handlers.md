# API Layer (Tasks 14-17)

> Back to [Overview](./00-overview.md)

---

## Task 14: Workflow API Handler

**Files:**
- Create: `internal/api/handlers/workflows.go`
- Create: `internal/api/handlers/workflows_test.go`

**Step 1: Write the failing test**

Create `internal/api/handlers/workflows_test.go`:
```go
package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/service"
)

func TestWorkflowsHandler_Create(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := service.NewWorkflowService(repo)
	handler := NewWorkflowsHandler(svc)

	body := `{"projectId":"proj-123"}`
	req := httptest.NewRequest("POST", "/api/v1/orgs/org-456/workflows", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")

	// Add chi URL params
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-456")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	rr := httptest.NewRecorder()
	handler.Create(rr, req)

	if rr.Code != http.StatusCreated {
		t.Errorf("Create() status = %d, want %d, body = %s", rr.Code, http.StatusCreated, rr.Body.String())
	}

	var response map[string]any
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Fatalf("Failed to parse response: %v", err)
	}

	if response["id"] == nil {
		t.Error("Create() response should contain id")
	}
	if response["status"] != "draft" {
		t.Errorf("Create() status = %v, want draft", response["status"])
	}
}

func TestWorkflowsHandler_Get(t *testing.T) {
	repo := memory.NewWorkflowRepository()
	svc := service.NewWorkflowService(repo)
	handler := NewWorkflowsHandler(svc)

	// Create a workflow first
	wf, _ := svc.CreateWorkflow(context.Background(), service.CreateWorkflowInput{
		ProjectID: "proj-123",
		OrgID:     "org-456",
		CreatedBy: "user-789",
	})

	req := httptest.NewRequest("GET", "/api/v1/orgs/org-456/workflows/"+wf.ID, nil)

	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-456")
	rctx.URLParams.Add("id", wf.ID)
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	rr := httptest.NewRecorder()
	handler.Get(rr, req)

	if rr.Code != http.StatusOK {
		t.Errorf("Get() status = %d, want %d", rr.Code, http.StatusOK)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test -v ./internal/api/handlers/... -run TestWorkflowsHandler`

Expected: FAIL with "undefined: NewWorkflowsHandler"

**Step 3: Write handler**

Create `internal/api/handlers/workflows.go`:
```go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

// WorkflowsHandler handles workflow HTTP requests
type WorkflowsHandler struct {
	svc *service.WorkflowService
}

// NewWorkflowsHandler creates a new handler instance
func NewWorkflowsHandler(svc *service.WorkflowService) *WorkflowsHandler {
	return &WorkflowsHandler{svc: svc}
}

type createWorkflowRequest struct {
	ProjectID string `json:"projectId"`
}

// Create handles POST /orgs/{orgID}/workflows
func (h *WorkflowsHandler) Create(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")

	var req createWorkflowRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}

	input := service.CreateWorkflowInput{
		ProjectID: req.ProjectID,
		OrgID:     orgID,
		CreatedBy: "system", // TODO: get from auth context
	}

	wf, err := h.svc.CreateWorkflow(r.Context(), input)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(wf)
}

// Get handles GET /orgs/{orgID}/workflows/{id}
func (h *WorkflowsHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	wf, err := h.svc.GetWorkflow(r.Context(), id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(wf)
}

// List handles GET /orgs/{orgID}/workflows
func (h *WorkflowsHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")

	workflows, err := h.svc.ListWorkflows(r.Context(), orgID)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(workflows)
}

// Start handles POST /orgs/{orgID}/workflows/{id}/start
func (h *WorkflowsHandler) Start(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	wf, err := h.svc.StartWorkflow(r.Context(), id, "system") // TODO: get from auth context
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(wf)
}
```

**Step 4: Run test to verify it passes**

Run: `go test -v ./internal/api/handlers/... -run TestWorkflowsHandler`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/workflows.go internal/api/handlers/workflows_test.go
git commit -m "feat: add WorkflowsHandler with Create, Get, List, Start"
```

---

## Task 15: Wire Up Workflow Routes

**Files:**
- Modify: `internal/api/routes/routes.go`
- Modify: `cmd/api/main.go`

**Step 1: Update routes.go**

Modify `internal/api/routes/routes.go` to add workflow routes:
```go
package routes

import (
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/anthropics/agentic-platform/internal/api/handlers"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

func Setup(knowledgeRepo repository.KnowledgeRepository, workflowRepo repository.WorkflowRepository) *chi.Mux {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	// Health check
	r.Get("/health", handlers.HealthCheck)

	// Services
	knowledgeSvc := service.NewKnowledgeService(knowledgeRepo)
	workflowSvc := service.NewWorkflowService(workflowRepo)

	// Handlers
	guidelinesHandler := handlers.NewGuidelinesHandler(knowledgeSvc)
	constraintsHandler := handlers.NewConstraintsHandler(knowledgeSvc)
	templatesHandler := handlers.NewTemplatesHandler(knowledgeSvc)
	examplesHandler := handlers.NewExamplesHandler(knowledgeSvc)
	workflowsHandler := handlers.NewWorkflowsHandler(workflowSvc)

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		r.Route("/orgs/{orgID}", func(r chi.Router) {
			// Knowledge routes
			r.Route("/knowledge/{agentType}", func(r chi.Router) {
				// Guidelines
				r.Route("/guidelines", func(r chi.Router) {
					r.Post("/", guidelinesHandler.Create)
					r.Get("/", guidelinesHandler.List)
					r.Get("/{id}", guidelinesHandler.Get)
					r.Put("/{id}", guidelinesHandler.Update)
					r.Delete("/{id}", guidelinesHandler.Deactivate)
				})

				// Constraints
				r.Route("/constraints", func(r chi.Router) {
					r.Post("/", constraintsHandler.Create)
					r.Get("/", constraintsHandler.List)
					r.Get("/{id}", constraintsHandler.Get)
					r.Delete("/{id}", constraintsHandler.Deactivate)
				})

				// Templates
				r.Route("/templates", func(r chi.Router) {
					r.Post("/", templatesHandler.Create)
					r.Get("/", templatesHandler.List)
					r.Get("/{id}", templatesHandler.Get)
					r.Delete("/{id}", templatesHandler.Deactivate)
				})

				// Examples
				r.Route("/examples", func(r chi.Router) {
					r.Post("/", examplesHandler.Create)
					r.Get("/", examplesHandler.List)
					r.Get("/{id}", examplesHandler.Get)
					r.Delete("/{id}", examplesHandler.Deactivate)
				})
			})

			// Workflow routes
			r.Route("/workflows", func(r chi.Router) {
				r.Post("/", workflowsHandler.Create)
				r.Get("/", workflowsHandler.List)
				r.Get("/{id}", workflowsHandler.Get)
				r.Post("/{id}/start", workflowsHandler.Start)
			})
		})
	})

	return r
}
```

**Step 2: Update main.go**

Modify `cmd/api/main.go`:
```go
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/anthropics/agentic-platform/internal/api/routes"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	knowledgeRepo := memory.NewKnowledgeRepository()
	workflowRepo := memory.NewWorkflowRepository()

	r := routes.Setup(knowledgeRepo, workflowRepo)

	log.Printf("Starting server on :%s", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal(err)
	}
}
```

**Step 3: Verify it compiles and runs**

Run: `go build ./... && go run cmd/api/main.go &`

Test:
```bash
curl -X POST http://localhost:8080/api/v1/orgs/org-123/workflows \
  -H "Content-Type: application/json" \
  -d '{"projectId":"proj-456"}'
```

Expected: JSON response with workflow data

**Step 4: Commit**

```bash
git add internal/api/routes/routes.go cmd/api/main.go
git commit -m "feat: wire up workflow API routes"
```

---

## Task 16: Add Complete Phase and Escalation Endpoints

**Files:**
- Modify: `internal/api/handlers/workflows.go`
- Modify: `internal/api/routes/routes.go`

**Step 1: Add CompletePhase handler**

Add to `internal/api/handlers/workflows.go`:
```go
import (
	...
	"github.com/anthropics/agentic-platform/internal/domain"
)

type completePhaseRequest struct {
	Phase string `json:"phase"`
}

// CompletePhase handles POST /orgs/{orgID}/workflows/{id}/phases/complete
func (h *WorkflowsHandler) CompletePhase(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var req completePhaseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}

	phase := domain.Phase(req.Phase)
	if !phase.IsValid() {
		http.Error(w, `{"error":"invalid phase"}`, http.StatusBadRequest)
		return
	}

	wf, err := h.svc.CompletePhase(r.Context(), id, phase, "system") // TODO: get from auth context
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(wf)
}

type createEscalationRequest struct {
	ArtifactID   string           `json:"artifactId"`
	ConstraintID string           `json:"constraintId"`
	Attempts     []domain.Attempt `json:"attempts"`
}

// CreateEscalation handles POST /orgs/{orgID}/workflows/{id}/escalations
func (h *WorkflowsHandler) CreateEscalation(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var req createEscalationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}

	input := service.CreateEscalationInput{
		WorkflowID:   id,
		ArtifactID:   req.ArtifactID,
		ConstraintID: req.ConstraintID,
		Attempts:     req.Attempts,
	}

	esc, err := h.svc.CreateEscalation(r.Context(), input)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(esc)
}

// ListEscalations handles GET /orgs/{orgID}/workflows/{id}/escalations
func (h *WorkflowsHandler) ListEscalations(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	escalations, err := h.svc.ListEscalationsByWorkflow(r.Context(), id)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(escalations)
}

type resolveEscalationRequest struct {
	Action string `json:"action"`
	Reason string `json:"reason"`
}

// ResolveEscalation handles POST /orgs/{orgID}/workflows/{workflowID}/escalations/{id}/resolve
func (h *WorkflowsHandler) ResolveEscalation(w http.ResponseWriter, r *http.Request) {
	escID := chi.URLParam(r, "escID")

	var req resolveEscalationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}

	input := service.ResolveEscalationInput{
		EscalationID: escID,
		Action:       req.Action,
		UserID:       "system", // TODO: get from auth context
		Reason:       req.Reason,
	}

	esc, err := h.svc.ResolveEscalation(r.Context(), input)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
			return
		}
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(esc)
}
```

**Step 2: Add routes**

Update workflow routes in `internal/api/routes/routes.go`:
```go
// Workflow routes
r.Route("/workflows", func(r chi.Router) {
	r.Post("/", workflowsHandler.Create)
	r.Get("/", workflowsHandler.List)
	r.Get("/{id}", workflowsHandler.Get)
	r.Post("/{id}/start", workflowsHandler.Start)
	r.Post("/{id}/phases/complete", workflowsHandler.CompletePhase)

	// Escalation routes
	r.Post("/{id}/escalations", workflowsHandler.CreateEscalation)
	r.Get("/{id}/escalations", workflowsHandler.ListEscalations)
	r.Post("/{id}/escalations/{escID}/resolve", workflowsHandler.ResolveEscalation)
})
```

**Step 3: Verify it compiles**

Run: `go build ./...`

Expected: Success

**Step 4: Commit**

```bash
git add internal/api/handlers/workflows.go internal/api/routes/routes.go
git commit -m "feat: add phase completion and escalation API endpoints"
```

---

## Task 17: Run All Tests

**Files:** None (verification only)

**Step 1: Run all tests**

Run: `go test -v ./...`

Expected: All tests pass

**Step 2: Run with coverage**

Run: `go test -cover ./...`

Document coverage percentages.

**Step 3: Commit any fixes needed**

If tests fail, fix and commit.
