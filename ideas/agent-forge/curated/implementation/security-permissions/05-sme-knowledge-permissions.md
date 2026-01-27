# Part 5: SME Knowledge Permissions

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement marketplace enablement tracking and mandatory knowledge enforcement.

**Architecture:** Extend permissions repository for marketplace enablement. Add methods to query effective knowledge for a project (org knowledge + enabled marketplace items + mandatory items).

**Tech Stack:** Go, following existing codebase patterns

**Prerequisite:** Complete [04-authorization-middleware.md](./04-authorization-middleware.md) first.

---

## Task 1: Add Marketplace Enablement Repository Methods

**Files:**
- Modify: `internal/repository/memory/permissions_repository.go`
- Modify: `internal/repository/memory/permissions_repository_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/repository/memory/permissions_repository_test.go
func TestPermissionsRepository_MarketplaceEnablement(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	enablement := &domain.MarketplaceEnablement{
		ID:          "me-1",
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
		EnabledAt:   time.Now(),
	}

	// Create
	err := repo.CreateMarketplaceEnablement(ctx, enablement)
	if err != nil {
		t.Fatalf("CreateMarketplaceEnablement() error = %v", err)
	}

	// Create duplicate - should fail
	err = repo.CreateMarketplaceEnablement(ctx, enablement)
	if err != repository.ErrAlreadyExists {
		t.Errorf("CreateMarketplaceEnablement() duplicate error = %v, want ErrAlreadyExists", err)
	}

	// Get
	got, err := repo.GetMarketplaceEnablement(ctx, "org-1", "k-1")
	if err != nil {
		t.Fatalf("GetMarketplaceEnablement() error = %v", err)
	}
	if got.EnabledBy != "admin-1" {
		t.Errorf("EnabledBy = %v, want admin-1", got.EnabledBy)
	}

	// Get non-existent
	_, err = repo.GetMarketplaceEnablement(ctx, "org-1", "k-999")
	if err != repository.ErrNotFound {
		t.Errorf("GetMarketplaceEnablement() non-existent error = %v, want ErrNotFound", err)
	}
}

func TestPermissionsRepository_ListMarketplaceEnablements(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	enablements := []*domain.MarketplaceEnablement{
		{ID: "me-1", OrgID: "org-1", KnowledgeID: "k-1", EnabledBy: "admin-1"},
		{ID: "me-2", OrgID: "org-1", KnowledgeID: "k-2", EnabledBy: "admin-1"},
		{ID: "me-3", OrgID: "org-2", KnowledgeID: "k-1", EnabledBy: "admin-2"},
	}

	for _, e := range enablements {
		_ = repo.CreateMarketplaceEnablement(ctx, e)
	}

	// List by org
	org1Enablements, err := repo.ListMarketplaceEnablements(ctx, "org-1")
	if err != nil {
		t.Fatalf("ListMarketplaceEnablements() error = %v", err)
	}
	if len(org1Enablements) != 2 {
		t.Errorf("ListMarketplaceEnablements() count = %v, want 2", len(org1Enablements))
	}
}

func TestPermissionsRepository_DeleteMarketplaceEnablement(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	enablement := &domain.MarketplaceEnablement{
		ID:          "me-1",
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	}
	_ = repo.CreateMarketplaceEnablement(ctx, enablement)

	// Delete
	err := repo.DeleteMarketplaceEnablement(ctx, "org-1", "k-1")
	if err != nil {
		t.Fatalf("DeleteMarketplaceEnablement() error = %v", err)
	}

	// Verify deleted
	_, err = repo.GetMarketplaceEnablement(ctx, "org-1", "k-1")
	if err != repository.ErrNotFound {
		t.Errorf("GetMarketplaceEnablement() after delete error = %v, want ErrNotFound", err)
	}

	// Delete non-existent
	err = repo.DeleteMarketplaceEnablement(ctx, "org-1", "k-999")
	if err != repository.ErrNotFound {
		t.Errorf("DeleteMarketplaceEnablement() non-existent error = %v, want ErrNotFound", err)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository_Marketplace -v`
Expected: FAIL with method not defined

**Step 3: Write minimal implementation**

```go
// Add to internal/repository/memory/permissions_repository.go

func (r *PermissionsRepository) marketplaceKey(orgID, knowledgeID string) string {
	return orgID + "/" + knowledgeID
}

// CreateMarketplaceEnablement creates a new marketplace enablement
func (r *PermissionsRepository) CreateMarketplaceEnablement(ctx context.Context, m *domain.MarketplaceEnablement) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.marketplaceKey(m.OrgID, m.KnowledgeID)
	if _, exists := r.marketplaceEnablements[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *m
	r.marketplaceEnablements[key] = &copy
	return nil
}

// GetMarketplaceEnablement retrieves a marketplace enablement
func (r *PermissionsRepository) GetMarketplaceEnablement(ctx context.Context, orgID, knowledgeID string) (*domain.MarketplaceEnablement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := r.marketplaceKey(orgID, knowledgeID)
	m, exists := r.marketplaceEnablements[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *m
	return &copy, nil
}

// ListMarketplaceEnablements returns all marketplace enablements for an org
func (r *PermissionsRepository) ListMarketplaceEnablements(ctx context.Context, orgID string) ([]*domain.MarketplaceEnablement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.MarketplaceEnablement
	for _, m := range r.marketplaceEnablements {
		if m.OrgID == orgID {
			copy := *m
			result = append(result, &copy)
		}
	}
	return result, nil
}

// DeleteMarketplaceEnablement removes a marketplace enablement
func (r *PermissionsRepository) DeleteMarketplaceEnablement(ctx context.Context, orgID, knowledgeID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.marketplaceKey(orgID, knowledgeID)
	if _, exists := r.marketplaceEnablements[key]; !exists {
		return repository.ErrNotFound
	}

	delete(r.marketplaceEnablements, key)
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository_Marketplace -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/permissions_repository.go internal/repository/memory/permissions_repository_test.go
git commit -m "feat(permissions): add marketplace enablement repository methods"
```

---

## Task 2: Create Marketplace Service

**Files:**
- Create: `internal/service/marketplace_service.go`
- Create: `internal/service/marketplace_service_test.go`

**Step 1: Write the failing test**

```go
// internal/service/marketplace_service_test.go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func TestMarketplaceService_EnableItem(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewMarketplaceService(repo)
	ctx := context.Background()

	input := EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	}

	enablement, err := svc.EnableItem(ctx, input)
	if err != nil {
		t.Fatalf("EnableItem() error = %v", err)
	}

	if enablement.KnowledgeID != "k-1" {
		t.Errorf("KnowledgeID = %v, want k-1", enablement.KnowledgeID)
	}

	// Enable duplicate - should fail
	_, err = svc.EnableItem(ctx, input)
	if err == nil {
		t.Error("EnableItem() duplicate should fail")
	}
}

func TestMarketplaceService_DisableItem(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewMarketplaceService(repo)
	ctx := context.Background()

	// Enable first
	_, _ = svc.EnableItem(ctx, EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	})

	// Disable
	err := svc.DisableItem(ctx, "org-1", "k-1")
	if err != nil {
		t.Fatalf("DisableItem() error = %v", err)
	}

	// Verify disabled
	enabled, _ := svc.IsItemEnabled(ctx, "org-1", "k-1")
	if enabled {
		t.Error("Item should be disabled")
	}
}

func TestMarketplaceService_ListEnabled(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewMarketplaceService(repo)
	ctx := context.Background()

	// Enable some items
	_, _ = svc.EnableItem(ctx, EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	})
	_, _ = svc.EnableItem(ctx, EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-2",
		EnabledBy:   "admin-1",
	})

	enabled, err := svc.ListEnabled(ctx, "org-1")
	if err != nil {
		t.Fatalf("ListEnabled() error = %v", err)
	}

	if len(enabled) != 2 {
		t.Errorf("ListEnabled() count = %v, want 2", len(enabled))
	}
}

func TestMarketplaceService_IsItemEnabled(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewMarketplaceService(repo)
	ctx := context.Background()

	// Enable an item
	_, _ = svc.EnableItem(ctx, EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	})

	// Check enabled
	enabled, err := svc.IsItemEnabled(ctx, "org-1", "k-1")
	if err != nil {
		t.Fatalf("IsItemEnabled() error = %v", err)
	}
	if !enabled {
		t.Error("k-1 should be enabled")
	}

	// Check not enabled
	enabled, err = svc.IsItemEnabled(ctx, "org-1", "k-2")
	if err != nil {
		t.Fatalf("IsItemEnabled() error = %v", err)
	}
	if enabled {
		t.Error("k-2 should NOT be enabled")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run TestMarketplaceService -v`
Expected: FAIL with "undefined: NewMarketplaceService"

**Step 3: Write minimal implementation**

```go
// internal/service/marketplace_service.go
package service

import (
	"context"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// MarketplaceService handles marketplace enablement business logic
type MarketplaceService struct {
	repo repository.PermissionsRepository
}

// NewMarketplaceService creates a new marketplace service
func NewMarketplaceService(repo repository.PermissionsRepository) *MarketplaceService {
	return &MarketplaceService{repo: repo}
}

// EnableMarketplaceItemInput contains fields for enabling a marketplace item
type EnableMarketplaceItemInput struct {
	OrgID       string
	KnowledgeID string
	EnabledBy   string
}

// EnableItem enables a marketplace item for an organization
func (s *MarketplaceService) EnableItem(ctx context.Context, input EnableMarketplaceItemInput) (*domain.MarketplaceEnablement, error) {
	enablement := &domain.MarketplaceEnablement{
		ID:          generateEnablementID(),
		OrgID:       input.OrgID,
		KnowledgeID: input.KnowledgeID,
		EnabledBy:   input.EnabledBy,
		EnabledAt:   time.Now(),
	}

	if err := enablement.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateMarketplaceEnablement(ctx, enablement); err != nil {
		return nil, err
	}

	return enablement, nil
}

// DisableItem disables a marketplace item for an organization
func (s *MarketplaceService) DisableItem(ctx context.Context, orgID, knowledgeID string) error {
	return s.repo.DeleteMarketplaceEnablement(ctx, orgID, knowledgeID)
}

// ListEnabled returns all enabled marketplace items for an organization
func (s *MarketplaceService) ListEnabled(ctx context.Context, orgID string) ([]*domain.MarketplaceEnablement, error) {
	return s.repo.ListMarketplaceEnablements(ctx, orgID)
}

// IsItemEnabled checks if a marketplace item is enabled for an organization
func (s *MarketplaceService) IsItemEnabled(ctx context.Context, orgID, knowledgeID string) (bool, error) {
	_, err := s.repo.GetMarketplaceEnablement(ctx, orgID, knowledgeID)
	if err != nil {
		if err == repository.ErrNotFound {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// GetEnabledKnowledgeIDs returns the list of enabled knowledge IDs for an org
func (s *MarketplaceService) GetEnabledKnowledgeIDs(ctx context.Context, orgID string) ([]string, error) {
	enablements, err := s.repo.ListMarketplaceEnablements(ctx, orgID)
	if err != nil {
		return nil, err
	}

	ids := make([]string, len(enablements))
	for i, e := range enablements {
		ids[i] = e.KnowledgeID
	}
	return ids, nil
}

func generateEnablementID() string {
	return "me-" + randomString(12)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run TestMarketplaceService -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/marketplace_service.go internal/service/marketplace_service_test.go
git commit -m "feat(permissions): add marketplace service"
```

---

## Task 3: Create Marketplace HTTP Handler

**Files:**
- Create: `internal/api/handlers/marketplace.go`
- Create: `internal/api/handlers/marketplace_test.go`

**Step 1: Write the failing test**

```go
// internal/api/handlers/marketplace_test.go
package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/service"
)

func TestMarketplaceHandler_Enable(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewMarketplaceService(repo)
	handler := NewMarketplaceHandler(svc)

	reqBody := EnableMarketplaceRequest{
		KnowledgeID: "k-1",
	}
	body, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/orgs/org-1/marketplace", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "admin-1")
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Enable(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %d, want %d. Body: %s", w.Code, http.StatusCreated, w.Body.String())
	}

	var resp domain.MarketplaceEnablement
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.KnowledgeID != "k-1" {
		t.Errorf("KnowledgeID = %s, want k-1", resp.KnowledgeID)
	}
}

func TestMarketplaceHandler_List(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewMarketplaceService(repo)
	handler := NewMarketplaceHandler(svc)

	ctx := context.Background()
	_, _ = svc.EnableItem(ctx, service.EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	})
	_, _ = svc.EnableItem(ctx, service.EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-2",
		EnabledBy:   "admin-1",
	})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/orgs/org-1/marketplace", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.List(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
	}

	var resp []*domain.MarketplaceEnablement
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if len(resp) != 2 {
		t.Errorf("Count = %d, want 2", len(resp))
	}
}

func TestMarketplaceHandler_Disable(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewMarketplaceService(repo)
	handler := NewMarketplaceHandler(svc)

	ctx := context.Background()
	_, _ = svc.EnableItem(ctx, service.EnableMarketplaceItemInput{
		OrgID:       "org-1",
		KnowledgeID: "k-1",
		EnabledBy:   "admin-1",
	})

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/orgs/org-1/marketplace/k-1", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	rctx.URLParams.Add("knowledgeID", "k-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Disable(w, req)

	if w.Code != http.StatusNoContent {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusNoContent)
	}

	// Verify disabled
	enabled, _ := svc.IsItemEnabled(ctx, "org-1", "k-1")
	if enabled {
		t.Error("Item should be disabled")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -run TestMarketplaceHandler -v`
Expected: FAIL with "undefined: NewMarketplaceHandler"

**Step 3: Write minimal implementation**

```go
// internal/api/handlers/marketplace.go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

// MarketplaceHandler handles marketplace enablement HTTP requests
type MarketplaceHandler struct {
	svc *service.MarketplaceService
}

// NewMarketplaceHandler creates a new marketplace handler
func NewMarketplaceHandler(svc *service.MarketplaceService) *MarketplaceHandler {
	return &MarketplaceHandler{svc: svc}
}

// EnableMarketplaceRequest is the request body for enabling a marketplace item
type EnableMarketplaceRequest struct {
	KnowledgeID string `json:"knowledgeId"`
}

// List handles GET /api/v1/orgs/{orgID}/marketplace
func (h *MarketplaceHandler) List(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")

	enablements, err := h.svc.ListEnabled(r.Context(), orgID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if enablements == nil {
		enablements = []*domain.MarketplaceEnablement{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(enablements)
}

// Enable handles POST /api/v1/orgs/{orgID}/marketplace
func (h *MarketplaceHandler) Enable(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		userID = "system"
	}

	var req EnableMarketplaceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.EnableMarketplaceItemInput{
		OrgID:       orgID,
		KnowledgeID: req.KnowledgeID,
		EnabledBy:   userID,
	}

	enablement, err := h.svc.EnableItem(r.Context(), input)
	if err != nil {
		if err == repository.ErrAlreadyExists {
			http.Error(w, "item already enabled", http.StatusConflict)
			return
		}
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(enablement)
}

// Disable handles DELETE /api/v1/orgs/{orgID}/marketplace/{knowledgeID}
func (h *MarketplaceHandler) Disable(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	knowledgeID := chi.URLParam(r, "knowledgeID")

	err := h.svc.DisableItem(r.Context(), orgID, knowledgeID)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "item not enabled", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// Check handles GET /api/v1/orgs/{orgID}/marketplace/{knowledgeID}
func (h *MarketplaceHandler) Check(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	knowledgeID := chi.URLParam(r, "knowledgeID")

	enabled, err := h.svc.IsItemEnabled(r.Context(), orgID, knowledgeID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"enabled": enabled})
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/api/handlers/... -run TestMarketplaceHandler -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/marketplace.go internal/api/handlers/marketplace_test.go
git commit -m "feat(permissions): add marketplace HTTP handler"
```

---

## Task 4: Add Mandatory Knowledge to OrgService

**Files:**
- Modify: `internal/service/org_service.go`
- Modify: `internal/service/org_service_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/service/org_service_test.go
func TestOrgService_UpdateMandatoryKnowledge(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	// Create org
	org, _ := svc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	// Add mandatory knowledge
	updatedOrg, err := svc.UpdateMandatoryKnowledge(ctx, org.ID, []string{"k-1", "k-2"})
	if err != nil {
		t.Fatalf("UpdateMandatoryKnowledge() error = %v", err)
	}

	if len(updatedOrg.MandatoryKnowledge) != 2 {
		t.Errorf("MandatoryKnowledge count = %v, want 2", len(updatedOrg.MandatoryKnowledge))
	}

	// Verify persisted
	gotOrg, _ := svc.GetOrganization(ctx, org.ID)
	if len(gotOrg.MandatoryKnowledge) != 2 {
		t.Errorf("Persisted MandatoryKnowledge count = %v, want 2", len(gotOrg.MandatoryKnowledge))
	}
}

func TestOrgService_IsMandatoryKnowledge(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	// Create org with mandatory knowledge
	org, _ := svc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})
	_, _ = svc.UpdateMandatoryKnowledge(ctx, org.ID, []string{"k-1", "k-2"})

	// Check mandatory
	isMandatory, err := svc.IsMandatoryKnowledge(ctx, org.ID, "k-1")
	if err != nil {
		t.Fatalf("IsMandatoryKnowledge() error = %v", err)
	}
	if !isMandatory {
		t.Error("k-1 should be mandatory")
	}

	// Check non-mandatory
	isMandatory, err = svc.IsMandatoryKnowledge(ctx, org.ID, "k-3")
	if err != nil {
		t.Fatalf("IsMandatoryKnowledge() error = %v", err)
	}
	if isMandatory {
		t.Error("k-3 should NOT be mandatory")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run "TestOrgService_(UpdateMandatory|IsMandatory)" -v`
Expected: FAIL with method not defined

**Step 3: Write minimal implementation**

```go
// Add to internal/service/org_service.go

// UpdateMandatoryKnowledge updates the mandatory knowledge list for an organization
func (s *OrgService) UpdateMandatoryKnowledge(ctx context.Context, orgID string, knowledgeIDs []string) (*domain.Organization, error) {
	org, err := s.repo.GetOrganization(ctx, orgID)
	if err != nil {
		return nil, err
	}

	org.MandatoryKnowledge = knowledgeIDs
	org.UpdatedAt = time.Now()

	if err := s.repo.UpdateOrganization(ctx, org); err != nil {
		return nil, err
	}

	return org, nil
}

// IsMandatoryKnowledge checks if a knowledge item is mandatory for an organization
func (s *OrgService) IsMandatoryKnowledge(ctx context.Context, orgID, knowledgeID string) (bool, error) {
	org, err := s.repo.GetOrganization(ctx, orgID)
	if err != nil {
		return false, err
	}

	for _, id := range org.MandatoryKnowledge {
		if id == knowledgeID {
			return true, nil
		}
	}
	return false, nil
}

// GetMandatoryKnowledge returns the list of mandatory knowledge IDs for an organization
func (s *OrgService) GetMandatoryKnowledge(ctx context.Context, orgID string) ([]string, error) {
	org, err := s.repo.GetOrganization(ctx, orgID)
	if err != nil {
		return nil, err
	}

	return org.MandatoryKnowledge, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run "TestOrgService_(UpdateMandatory|IsMandatory)" -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/org_service.go internal/service/org_service_test.go
git commit -m "feat(permissions): add mandatory knowledge management to org service"
```

---

## Task 5: Register Marketplace Routes

**Files:**
- Modify: `internal/api/routes/routes.go`

**Step 1: Add marketplace routes**

```go
// In Setup function, add marketplace service and handler
marketplaceSvc := service.NewMarketplaceService(permissionsRepo)
marketplaceHandler := handlers.NewMarketplaceHandler(marketplaceSvc)

// Add marketplace routes under org routes (requires SME Curator or Admin)
r.Route("/{orgID}", func(r chi.Router) {
	// ... existing routes

	// Marketplace routes (requires SME Curator or Admin)
	r.Route("/marketplace", func(r chi.Router) {
		r.Use(permMW.RequireOrgRole(domain.OrgRoleSMECurator))
		r.Get("/", marketplaceHandler.List)
		r.Post("/", marketplaceHandler.Enable)
		r.Get("/{knowledgeID}", marketplaceHandler.Check)
		r.Delete("/{knowledgeID}", marketplaceHandler.Disable)
	})
})
```

**Step 2: Run build to verify compilation**

Run: `go build ./...`
Expected: No errors

**Step 3: Commit**

```bash
git add internal/api/routes/routes.go
git commit -m "feat(permissions): register marketplace routes"
```

---

## Task 6: Run All Tests

**Step 1: Run all tests**

Run: `go test ./internal/... -v`
Expected: All tests PASS

**Step 2: Run linter**

Run: `go vet ./internal/...`
Expected: No errors

**Step 3: Final commit for part 5**

```bash
git add -A
git commit -m "feat(permissions): complete SME knowledge permissions

- Add marketplace enablement repository methods
- Add MarketplaceService for enable/disable operations
- Add MarketplaceHandler with HTTP endpoints
- Add mandatory knowledge management to OrgService
- Register marketplace routes with permission middleware"
```

---

## Summary

After completing Part 5, you will have:

**Modified Files:**
- `internal/repository/memory/permissions_repository.go` - Added marketplace methods
- `internal/repository/memory/permissions_repository_test.go` - Added tests
- `internal/service/org_service.go` - Added mandatory knowledge methods
- `internal/service/org_service_test.go` - Added tests
- `internal/api/routes/routes.go` - Added marketplace routes

**Created Files:**
- `internal/service/marketplace_service.go` - Marketplace service
- `internal/service/marketplace_service_test.go` - Service tests
- `internal/api/handlers/marketplace.go` - HTTP handlers
- `internal/api/handlers/marketplace_test.go` - Handler tests

**API Endpoints:**
- `GET /api/v1/orgs/{orgID}/marketplace` - List enabled items
- `POST /api/v1/orgs/{orgID}/marketplace` - Enable marketplace item
- `GET /api/v1/orgs/{orgID}/marketplace/{knowledgeID}` - Check if enabled
- `DELETE /api/v1/orgs/{orgID}/marketplace/{knowledgeID}` - Disable item

**Features:**
- Enable/disable marketplace knowledge items per org
- Check if specific item is enabled
- List all enabled items
- Mandatory knowledge management
- Route-level permission enforcement (SME Curator/Admin required)

---

## Implementation Complete

You have now completed the full security permissions implementation:

1. **Part 1**: Data models for organizations, memberships, and roles
2. **Part 2**: Organization management and member CRUD
3. **Part 3**: Project membership with role hierarchy
4. **Part 4**: Authorization middleware with admin override
5. **Part 5**: SME knowledge permissions and marketplace enablement

### Final Integration Test

Create a comprehensive integration test to verify all components work together:

```go
// internal/integration_test.go
func TestSecurityPermissions_Integration(t *testing.T) {
	// Setup
	permissionsRepo := memory.NewPermissionsRepository()
	orgSvc := service.NewOrgService(permissionsRepo)
	projectPermsSvc := service.NewProjectPermissionsService(permissionsRepo)
	marketplaceSvc := service.NewMarketplaceService(permissionsRepo)
	authSvc := service.NewAuthService(permissionsRepo, orgSvc, projectPermsSvc)

	ctx := context.Background()

	// 1. Create org (user becomes admin)
	org, _ := orgSvc.CreateOrganization(ctx, service.CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	// 2. Admin adds member
	_, _ = orgSvc.AddMember(ctx, service.AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "developer-1",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	})

	// 3. Admin creates project, adds developer
	_, _ = projectPermsSvc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "admin-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "admin-1",
	})
	_, _ = projectPermsSvc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "developer-1",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "admin-1",
	})

	// 4. Verify developer can edit but not manage members
	canEdit, _ := authSvc.HasProjectRole(ctx, "developer-1", org.ID, "proj-1", domain.ProjectRoleEditor)
	canManage, _ := authSvc.HasProjectRole(ctx, "developer-1", org.ID, "proj-1", domain.ProjectRoleOwner)

	if !canEdit {
		t.Error("Developer should be able to edit")
	}
	if canManage {
		t.Error("Developer should NOT be able to manage members")
	}

	// 5. Verify admin override
	canAdminAccess, _ := authSvc.HasProjectRole(ctx, "admin-1", org.ID, "proj-1", domain.ProjectRoleOwner)
	if !canAdminAccess {
		t.Error("Admin should have access via override")
	}

	// 6. Enable marketplace item
	_, _ = marketplaceSvc.EnableItem(ctx, service.EnableMarketplaceItemInput{
		OrgID:       org.ID,
		KnowledgeID: "marketplace-k1",
		EnabledBy:   "admin-1",
	})

	enabled, _ := marketplaceSvc.IsItemEnabled(ctx, org.ID, "marketplace-k1")
	if !enabled {
		t.Error("Marketplace item should be enabled")
	}

	// 7. Set mandatory knowledge
	_, _ = orgSvc.UpdateMandatoryKnowledge(ctx, org.ID, []string{"mandatory-k1"})
	isMandatory, _ := orgSvc.IsMandatoryKnowledge(ctx, org.ID, "mandatory-k1")
	if !isMandatory {
		t.Error("Knowledge should be mandatory")
	}
}
```

Run: `go test ./internal/... -run TestSecurityPermissions_Integration -v`

### Next Steps

Consider implementing:
- Audit logging for permission changes
- Rate limiting on permission checks
- Caching for frequently accessed permissions
- Firestore implementation of the repository
