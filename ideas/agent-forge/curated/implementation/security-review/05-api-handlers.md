# Security Review: API Handlers

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add HTTP endpoints for security review operations.

**Prerequisites:** Complete `01-data-models.md`, `02-repository.md`, `03-service.md`

**Files:**
- Create: `internal/api/handlers/security.go`
- Create: `internal/api/handlers/security_test.go`

---

## Task 1: Create Security Handler Structure

**Files:**
- Create: `internal/api/handlers/security.go`
- Create: `internal/api/handlers/security_test.go`

**Step 1: Write the test**

```go
package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/your-org/agentic-platform/internal/repository"
	"github.com/your-org/agentic-platform/internal/service"
)

func TestNewSecurityHandler(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	if handler == nil {
		t.Fatal("NewSecurityHandler returned nil")
	}
	if handler.svc == nil {
		t.Error("svc should not be nil")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestNewSecurityHandler`

Expected: FAIL - SecurityHandler not defined

**Step 3: Write the implementation**

Create `internal/api/handlers/security.go`:

```go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/your-org/agentic-platform/internal/service"
)

// SecurityHandler handles security review HTTP endpoints
type SecurityHandler struct {
	svc *service.SecurityService
}

// NewSecurityHandler creates a new security handler
func NewSecurityHandler(svc *service.SecurityService) *SecurityHandler {
	return &SecurityHandler{svc: svc}
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestNewSecurityHandler`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go
git commit -m "$(cat <<'EOF'
feat(api): add SecurityHandler skeleton

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add GetReview Endpoint

**Files:**
- Modify: `internal/api/handlers/security.go`
- Modify: `internal/api/handlers/security_test.go`

**Step 1: Write the test**

Add to `internal/api/handlers/security_test.go`:

```go
func TestSecurityHandler_GetReview(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	// Create a review first
	ctx := context.Background()
	review, _ := svc.StartSecurityReview(ctx, service.StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	})

	// Setup router
	r := chi.NewRouter()
	r.Get("/reviews/{reviewID}", handler.GetReview)

	// Make request
	req := httptest.NewRequest("GET", "/reviews/"+review.ID, nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("got status %d, want %d", w.Code, http.StatusOK)
	}

	var response map[string]any
	json.NewDecoder(w.Body).Decode(&response)

	if response["id"] != review.ID {
		t.Errorf("got id %v, want %s", response["id"], review.ID)
	}
}

func TestSecurityHandler_GetReview_NotFound(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	r := chi.NewRouter()
	r.Get("/reviews/{reviewID}", handler.GetReview)

	req := httptest.NewRequest("GET", "/reviews/nonexistent", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("got status %d, want %d", w.Code, http.StatusNotFound)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_GetReview`

Expected: FAIL - GetReview method not defined

**Step 3: Write the implementation**

Add to `internal/api/handlers/security.go`:

```go
// GetReview retrieves a security review by ID
func (h *SecurityHandler) GetReview(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	reviewID := chi.URLParam(r, "reviewID")

	review, err := h.svc.GetSecurityReview(ctx, reviewID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if review == nil {
		http.Error(w, "review not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(review)
}
```

Also add a GetSecurityReview method to the service if not already present:

```go
// GetSecurityReview retrieves a security review by ID
func (s *SecurityService) GetSecurityReview(ctx context.Context, id string) (*domain.SecurityReview, error) {
	return s.repo.GetSecurityReview(ctx, id)
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_GetReview`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go internal/service/security_service.go
git commit -m "$(cat <<'EOF'
feat(api): add GetReview endpoint

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add ListFindings Endpoint

**Files:**
- Modify: `internal/api/handlers/security.go`
- Modify: `internal/api/handlers/security_test.go`

**Step 1: Write the test**

Add to `internal/api/handlers/security_test.go`:

```go
func TestSecurityHandler_ListFindings(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	ctx := context.Background()

	// Create review and finding
	review, _ := svc.StartSecurityReview(ctx, service.StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	})

	svc.CreateFinding(ctx, service.CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "main.go:45",
		Description:   "SQL injection",
		ProposedPatch: "Use parameterized query",
	})

	// Setup router
	r := chi.NewRouter()
	r.Get("/projects/{projectID}/findings", handler.ListFindings)

	req := httptest.NewRequest("GET", "/projects/project-1/findings", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("got status %d, want %d", w.Code, http.StatusOK)
	}

	var findings []map[string]any
	json.NewDecoder(w.Body).Decode(&findings)

	if len(findings) != 1 {
		t.Errorf("got %d findings, want 1", len(findings))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_ListFindings`

Expected: FAIL - ListFindings method not defined

**Step 3: Write the implementation**

Add to `internal/api/handlers/security.go`:

```go
// ListFindings returns all security findings for a project
func (h *SecurityHandler) ListFindings(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	projectID := chi.URLParam(r, "projectID")

	findings, err := h.svc.ListFindings(ctx, projectID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(findings)
}
```

Add to service:

```go
// ListFindings returns all findings for a project
func (s *SecurityService) ListFindings(ctx context.Context, projectID string) ([]*domain.SecurityFinding, error) {
	return s.repo.ListSecurityFindingsByProject(ctx, projectID)
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_ListFindings`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go internal/service/security_service.go
git commit -m "$(cat <<'EOF'
feat(api): add ListFindings endpoint

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add AcceptFinding Endpoint

**Files:**
- Modify: `internal/api/handlers/security.go`
- Modify: `internal/api/handlers/security_test.go`

**Step 1: Write the test**

Add to `internal/api/handlers/security_test.go`:

```go
func TestSecurityHandler_AcceptFinding(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	ctx := context.Background()

	// Create review and finding
	review, _ := svc.StartSecurityReview(ctx, service.StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	})

	finding, _ := svc.CreateFinding(ctx, service.CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "main.go:45",
		Description:   "SQL injection",
		ProposedPatch: "Use parameterized query",
	})

	// Setup router
	r := chi.NewRouter()
	r.Post("/findings/{findingID}/accept", handler.AcceptFinding)

	req := httptest.NewRequest("POST", "/findings/"+finding.ID+"/accept", nil)
	req.Header.Set("X-User-ID", "user-1")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("got status %d, want %d", w.Code, http.StatusOK)
	}

	var response map[string]any
	json.NewDecoder(w.Body).Decode(&response)

	if response["status"] != "accepted" {
		t.Errorf("got status %v, want accepted", response["status"])
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_AcceptFinding`

Expected: FAIL - AcceptFinding handler not defined

**Step 3: Write the implementation**

Add to `internal/api/handlers/security.go`:

```go
// AcceptFinding approves a security patch
func (h *SecurityHandler) AcceptFinding(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	findingID := chi.URLParam(r, "findingID")
	userID := r.Header.Get("X-User-ID")

	if userID == "" {
		http.Error(w, "X-User-ID header required", http.StatusBadRequest)
		return
	}

	finding, err := h.svc.AcceptFinding(ctx, service.AcceptFindingInput{
		FindingID: findingID,
		UserID:    userID,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(finding)
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_AcceptFinding`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go
git commit -m "$(cat <<'EOF'
feat(api): add AcceptFinding endpoint

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Add ProvideAlternative Endpoint

**Files:**
- Modify: `internal/api/handlers/security.go`
- Modify: `internal/api/handlers/security_test.go`

**Step 1: Write the test**

Add to `internal/api/handlers/security_test.go`:

```go
func TestSecurityHandler_ProvideAlternative(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	ctx := context.Background()

	// Create review and finding
	review, _ := svc.StartSecurityReview(ctx, service.StartSecurityReviewInput{
		ProjectID:  "project-1",
		WorkflowID: "workflow-1",
		OrgID:      "org-1",
	})

	finding, _ := svc.CreateFinding(ctx, service.CreateFindingInput{
		ReviewID:      review.ID,
		ProjectID:     "project-1",
		ArtifactID:    "artifact-1",
		Category:      domain.CategoryInjection,
		Severity:      domain.SeverityCritical,
		Location:      "main.go:45",
		Description:   "SQL injection",
		ProposedPatch: "Use parameterized query",
	})

	// Setup router
	r := chi.NewRouter()
	r.Post("/findings/{findingID}/alternative", handler.ProvideAlternative)

	body := `{"patch": "Use ORM instead"}`
	req := httptest.NewRequest("POST", "/findings/"+finding.ID+"/alternative", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "user-1")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("got status %d, want %d", w.Code, http.StatusOK)
	}

	var response map[string]any
	json.NewDecoder(w.Body).Decode(&response)

	if response["status"] != "user_alternative" {
		t.Errorf("got status %v, want user_alternative", response["status"])
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_ProvideAlternative`

Expected: FAIL - ProvideAlternative handler not defined

**Step 3: Write the implementation**

Add to `internal/api/handlers/security.go`:

```go
// AlternativeRequest represents the request body for providing an alternative patch
type AlternativeRequest struct {
	Patch string `json:"patch"`
}

// ProvideAlternative allows user to provide their own fix
func (h *SecurityHandler) ProvideAlternative(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	findingID := chi.URLParam(r, "findingID")
	userID := r.Header.Get("X-User-ID")

	if userID == "" {
		http.Error(w, "X-User-ID header required", http.StatusBadRequest)
		return
	}

	var req AlternativeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.Patch == "" {
		http.Error(w, "patch is required", http.StatusBadRequest)
		return
	}

	finding, err := h.svc.ProvideAlternative(ctx, service.ProvideAlternativeInput{
		FindingID:        findingID,
		UserID:           userID,
		AlternativePatch: req.Patch,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(finding)
}
```

Add `"strings"` to test imports.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_ProvideAlternative`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go
git commit -m "$(cat <<'EOF'
feat(api): add ProvideAlternative endpoint

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Add Route Registration

**Files:**
- Modify: `internal/api/handlers/security.go`

**Step 1: Write the test**

Add to `internal/api/handlers/security_test.go`:

```go
func TestSecurityHandler_RegisterRoutes(t *testing.T) {
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	handler := NewSecurityHandler(svc)

	r := chi.NewRouter()
	handler.RegisterRoutes(r)

	// Test that routes exist by making requests
	routes := []struct {
		method string
		path   string
	}{
		{"GET", "/reviews/test-id"},
		{"GET", "/projects/test-id/findings"},
		{"POST", "/findings/test-id/accept"},
		{"POST", "/findings/test-id/alternative"},
		{"POST", "/reviews/test-id/complete"},
	}

	for _, route := range routes {
		req := httptest.NewRequest(route.method, route.path, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		// 404 means route doesn't exist, anything else means it does
		if w.Code == http.StatusNotFound && w.Body.String() == "404 page not found\n" {
			t.Errorf("route %s %s not registered", route.method, route.path)
		}
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_RegisterRoutes`

Expected: FAIL - RegisterRoutes not defined

**Step 3: Write the implementation**

Add to `internal/api/handlers/security.go`:

```go
// RegisterRoutes registers security review routes on the router
func (h *SecurityHandler) RegisterRoutes(r chi.Router) {
	r.Get("/reviews/{reviewID}", h.GetReview)
	r.Post("/reviews/{reviewID}/complete", h.CompleteReview)
	r.Get("/projects/{projectID}/findings", h.ListFindings)
	r.Post("/findings/{findingID}/accept", h.AcceptFinding)
	r.Post("/findings/{findingID}/alternative", h.ProvideAlternative)
}

// CompleteReview marks a security review as completed
func (h *SecurityHandler) CompleteReview(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	reviewID := chi.URLParam(r, "reviewID")

	review, err := h.svc.CompleteSecurityReview(ctx, reviewID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(review)
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/api/handlers/... -v -run TestSecurityHandler_RegisterRoutes`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/security.go internal/api/handlers/security_test.go
git commit -m "$(cat <<'EOF'
feat(api): add route registration and CompleteReview endpoint

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, the API will expose:

| Method | Path | Handler |
|--------|------|---------|
| GET | `/reviews/{reviewID}` | GetReview |
| POST | `/reviews/{reviewID}/complete` | CompleteReview |
| GET | `/projects/{projectID}/findings` | ListFindings |
| POST | `/findings/{findingID}/accept` | AcceptFinding |
| POST | `/findings/{findingID}/alternative` | ProvideAlternative |

**Next:** Proceed to `06-frontend.md`
