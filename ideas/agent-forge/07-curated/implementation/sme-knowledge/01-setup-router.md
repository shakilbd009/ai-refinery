# Tasks 1-2: Go Project Setup and Chi Router

> **Navigation:** [Back to Overview](./00-overview.md) | Next: [Domain Models](./02-domain-models.md)

---

## Task 1: Go Project Setup

**Files:**
- Create: `go.mod`
- Create: `go.sum`
- Create: `cmd/api/main.go`
- Create: `Makefile`

**Step 1: Initialize Go module**

Run:
```bash
cd /Users/shikha/claude-projects/agentic-platform && go mod init github.com/anthropics/agentic-platform
```

Expected: `go.mod` created with module name

**Step 2: Create minimal main.go**

Create `cmd/api/main.go`:
```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	log.Printf("Starting server on :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
```

**Step 3: Create Makefile**

Create `Makefile`:
```makefile
.PHONY: run build test lint

run:
	go run cmd/api/main.go

build:
	go build -o bin/api cmd/api/main.go

test:
	go test -v ./...

lint:
	go vet ./...
```

**Step 4: Verify it runs**

Run: `make run`

In another terminal:
```bash
curl http://localhost:8080/health
```

Expected: `{"status":"ok"}`

**Step 5: Commit**

```bash
git add go.mod cmd/api/main.go Makefile
git commit -m "feat: initialize Go backend with health endpoint"
```

---

## Task 2: Add Chi Router

**Files:**
- Modify: `cmd/api/main.go`
- Create: `internal/api/routes/routes.go`
- Create: `internal/api/handlers/health.go`

**Step 1: Add Chi dependency**

Run:
```bash
go get github.com/go-chi/chi/v5
```

**Step 2: Create health handler**

Create `internal/api/handlers/health.go`:
```go
package handlers

import (
	"encoding/json"
	"net/http"
)

type HealthResponse struct {
	Status string `json:"status"`
}

func HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(HealthResponse{Status: "ok"})
}
```

**Step 3: Create routes setup**

Create `internal/api/routes/routes.go`:
```go
package routes

import (
	"github.com/anthropics/agentic-platform/internal/api/handlers"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func Setup() *chi.Mux {
	r := chi.NewRouter()

	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)

	r.Get("/health", handlers.HealthCheck)

	return r
}
```

**Step 4: Update main.go to use router**

Replace `cmd/api/main.go`:
```go
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/anthropics/agentic-platform/internal/api/routes"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	r := routes.Setup()

	log.Printf("Starting server on :%s", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal(err)
	}
}
```

**Step 5: Run and verify**

Run: `make run`

```bash
curl http://localhost:8080/health
```

Expected: `{"status":"ok"}`

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Chi router with structured handlers"
```
