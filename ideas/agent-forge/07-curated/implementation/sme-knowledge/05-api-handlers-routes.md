# Task 9: Wire Up Routes and Main

> **Navigation:** [Back to API Handlers](./05-api-handlers.md) | [Back to Overview](./00-overview.md)

---

## Task 9: Wire Up Routes and Main

**Files:**
- Modify: `internal/api/routes/routes.go`
- Modify: `cmd/api/main.go`

**Step 1: Update routes to include all handlers**

Replace `internal/api/routes/routes.go`:
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
		})
	})

	return r
}
```

**Step 2: Update main.go**

Replace `cmd/api/main.go`:
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

	// For now, use in-memory repository
	// TODO: Replace with Firestore in production
	repo := memory.NewKnowledgeRepository()

	r := routes.Setup(repo)

	log.Printf("Starting server on :%s", port)
	log.Printf("API available at http://localhost:%s/api/v1", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal(err)
	}
}
```

**Step 3: Run and test manually**

Run: `make run`

Test endpoints:
```bash
# Health
curl http://localhost:8080/health

# Create guideline
curl -X POST http://localhost:8080/api/v1/orgs/org1/knowledge/coding/guidelines \
  -H "Content-Type: application/json" \
  -H "X-User-ID: user1" \
  -d '{"title":"Error Handling","category":"errors","content":"Wrap all errors","priority":"must"}'

# List guidelines
curl http://localhost:8080/api/v1/orgs/org1/knowledge/coding/guidelines

# Create constraint
curl -X POST http://localhost:8080/api/v1/orgs/org1/knowledge/coding/constraints \
  -H "Content-Type: application/json" \
  -H "X-User-ID: user1" \
  -d '{"name":"No console.log","category":"blocklist","rule":"No console.log allowed","severity":"error"}'

# List constraints
curl http://localhost:8080/api/v1/orgs/org1/knowledge/coding/constraints
```

**Step 4: Run all tests**

Run: `make test`

Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: wire up API routes with in-memory repository"
```
