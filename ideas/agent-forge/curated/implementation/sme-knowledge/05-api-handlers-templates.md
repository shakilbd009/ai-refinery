# Task 10: Templates and Examples Handlers

> **Navigation:** [Back to API Handlers](./05-api-handlers.md) | [Back to Overview](./00-overview.md)

---

## Task 10: Add Templates and Examples Handlers

**Files:**
- Create: `internal/api/handlers/templates.go`
- Create: `internal/api/handlers/examples.go`
- Modify: `internal/api/routes/routes.go`

**Step 1: Create templates handler**

Create `internal/api/handlers/templates.go`:
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

type TemplatesHandler struct {
	svc *service.KnowledgeService
}

func NewTemplatesHandler(svc *service.KnowledgeService) *TemplatesHandler {
	return &TemplatesHandler{svc: svc}
}

type CreateTemplateRequest struct {
	Name        string                    `json:"name"`
	Description string                    `json:"description"`
	Type        string                    `json:"type"`
	Content     string                    `json:"content"`
	Variables   []domain.TemplateVariable `json:"variables"`
}

func (h *TemplatesHandler) Create(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")
	userID := r.Header.Get("X-User-ID")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	var req CreateTemplateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.CreateTemplateInput{
		OrgID:       orgID,
		AgentType:   agentType,
		Name:        req.Name,
		Description: req.Description,
		Type:        req.Type,
		Content:     req.Content,
		Variables:   req.Variables,
		CreatedBy:   userID,
	}

	template, err := h.svc.CreateTemplate(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(template)
}

func (h *TemplatesHandler) Get(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	template, err := h.svc.GetTemplate(r.Context(), orgID, id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(template)
}

func (h *TemplatesHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	templates, err := h.svc.ListTemplates(r.Context(), orgID, agentType)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if templates == nil {
		templates = []*domain.Template{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(templates)
}

func (h *TemplatesHandler) Deactivate(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	err := h.svc.DeactivateTemplate(r.Context(), orgID, id)
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

**Step 2: Create examples handler**

Create `internal/api/handlers/examples.go`:
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

type ExamplesHandler struct {
	svc *service.KnowledgeService
}

func NewExamplesHandler(svc *service.KnowledgeService) *ExamplesHandler {
	return &ExamplesHandler{svc: svc}
}

type CreateExampleRequest struct {
	Title       string `json:"title"`
	Scenario    string `json:"scenario"`
	GoodExample string `json:"goodExample"`
	BadExample  string `json:"badExample"`
	Explanation string `json:"explanation"`
}

func (h *ExamplesHandler) Create(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")
	userID := r.Header.Get("X-User-ID")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	var req CreateExampleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.CreateExampleInput{
		OrgID:       orgID,
		AgentType:   agentType,
		Title:       req.Title,
		Scenario:    req.Scenario,
		GoodExample: req.GoodExample,
		BadExample:  req.BadExample,
		Explanation: req.Explanation,
		CreatedBy:   userID,
	}

	example, err := h.svc.CreateExample(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(example)
}

func (h *ExamplesHandler) Get(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	example, err := h.svc.GetExample(r.Context(), orgID, id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(example)
}

func (h *ExamplesHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	agentTypeStr := chi.URLParam(r, "agentType")

	agentType := domain.AgentType(agentTypeStr)
	if !agentType.IsValid() {
		http.Error(w, "invalid agent type", http.StatusBadRequest)
		return
	}

	examples, err := h.svc.ListExamples(r.Context(), orgID, agentType)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if examples == nil {
		examples = []*domain.Example{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(examples)
}

func (h *ExamplesHandler) Deactivate(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	id := chi.URLParam(r, "id")

	err := h.svc.DeactivateExample(r.Context(), orgID, id)
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

**Step 3: Update routes (final version)**

Update `internal/api/routes/routes.go` to add templates and examples routes:
```go
package routes

import (
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/anthropics/agentic-platform/internal/api/handlers"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

func Setup(repo repository.KnowledgeRepository) *chi.Mux {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	// Health check
	r.Get("/health", handlers.HealthCheck)

	// Services
	knowledgeSvc := service.NewKnowledgeService(repo)

	// Handlers
	guidelinesHandler := handlers.NewGuidelinesHandler(knowledgeSvc)
	constraintsHandler := handlers.NewConstraintsHandler(knowledgeSvc)
	templatesHandler := handlers.NewTemplatesHandler(knowledgeSvc)
	examplesHandler := handlers.NewExamplesHandler(knowledgeSvc)

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		r.Route("/orgs/{orgID}/knowledge/{agentType}", func(r chi.Router) {
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
	})

	return r
}
```

**Step 4: Run all tests**

Run: `make test`

Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Templates and Examples API handlers"
```
