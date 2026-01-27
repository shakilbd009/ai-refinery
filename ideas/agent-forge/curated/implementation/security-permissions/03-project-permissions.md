# Part 3: Project Permissions

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement project membership management with role hierarchy (Owner > Editor > Approver > Viewer).

**Architecture:** Extend existing repository and add new service/handlers. Enforce at least one Owner per project. Follow patterns established in Part 2.

**Tech Stack:** Go, Chi router, following existing codebase patterns

**Prerequisite:** Complete [02-org-permissions.md](./02-org-permissions.md) first.

---

## Task 1: Add Project Membership Repository Methods

**Files:**
- Modify: `internal/repository/memory/permissions_repository.go`
- Modify: `internal/repository/memory/permissions_repository_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/repository/memory/permissions_repository_test.go
func TestPermissionsRepository_ProjectMembership(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	m := &domain.ProjectMembership{
		ID:        "pm-1",
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleEditor,
		AddedAt:   time.Now(),
	}

	// Create
	err := repo.CreateProjectMembership(ctx, m)
	if err != nil {
		t.Fatalf("CreateProjectMembership() error = %v", err)
	}

	// Create duplicate - should fail
	err = repo.CreateProjectMembership(ctx, m)
	if err != repository.ErrAlreadyExists {
		t.Errorf("CreateProjectMembership() duplicate error = %v, want ErrAlreadyExists", err)
	}

	// Get
	got, err := repo.GetProjectMembership(ctx, "proj-1", "user-1")
	if err != nil {
		t.Fatalf("GetProjectMembership() error = %v", err)
	}
	if got.Role != domain.ProjectRoleEditor {
		t.Errorf("Role = %v, want editor", got.Role)
	}

	// Get non-existent
	_, err = repo.GetProjectMembership(ctx, "proj-1", "user-999")
	if err != repository.ErrNotFound {
		t.Errorf("GetProjectMembership() non-existent error = %v, want ErrNotFound", err)
	}
}

func TestPermissionsRepository_ListProjectMemberships(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	memberships := []*domain.ProjectMembership{
		{ID: "pm-1", ProjectID: "proj-1", UserID: "user-1", Role: domain.ProjectRoleOwner},
		{ID: "pm-2", ProjectID: "proj-1", UserID: "user-2", Role: domain.ProjectRoleEditor},
		{ID: "pm-3", ProjectID: "proj-2", UserID: "user-1", Role: domain.ProjectRoleViewer},
	}

	for _, m := range memberships {
		_ = repo.CreateProjectMembership(ctx, m)
	}

	// List by project
	proj1Members, err := repo.ListProjectMemberships(ctx, "proj-1")
	if err != nil {
		t.Fatalf("ListProjectMemberships() error = %v", err)
	}
	if len(proj1Members) != 2 {
		t.Errorf("ListProjectMemberships() count = %v, want 2", len(proj1Members))
	}

	// List by user
	user1Projects, err := repo.ListUserProjectMemberships(ctx, "user-1")
	if err != nil {
		t.Fatalf("ListUserProjectMemberships() error = %v", err)
	}
	if len(user1Projects) != 2 {
		t.Errorf("ListUserProjectMemberships() count = %v, want 2", len(user1Projects))
	}
}

func TestPermissionsRepository_CountProjectOwners(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	memberships := []*domain.ProjectMembership{
		{ID: "pm-1", ProjectID: "proj-1", UserID: "user-1", Role: domain.ProjectRoleOwner},
		{ID: "pm-2", ProjectID: "proj-1", UserID: "user-2", Role: domain.ProjectRoleOwner},
		{ID: "pm-3", ProjectID: "proj-1", UserID: "user-3", Role: domain.ProjectRoleEditor},
	}

	for _, m := range memberships {
		_ = repo.CreateProjectMembership(ctx, m)
	}

	count, err := repo.CountProjectOwners(ctx, "proj-1")
	if err != nil {
		t.Fatalf("CountProjectOwners() error = %v", err)
	}
	if count != 2 {
		t.Errorf("CountProjectOwners() = %v, want 2", count)
	}
}

func TestPermissionsRepository_UpdateAndDeleteProjectMembership(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	m := &domain.ProjectMembership{
		ID:        "pm-1",
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleEditor,
	}
	_ = repo.CreateProjectMembership(ctx, m)

	// Update role
	m.Role = domain.ProjectRoleOwner
	err := repo.UpdateProjectMembership(ctx, m)
	if err != nil {
		t.Fatalf("UpdateProjectMembership() error = %v", err)
	}

	got, _ := repo.GetProjectMembership(ctx, "proj-1", "user-1")
	if got.Role != domain.ProjectRoleOwner {
		t.Errorf("Role = %v, want owner", got.Role)
	}

	// Delete
	err = repo.DeleteProjectMembership(ctx, "proj-1", "user-1")
	if err != nil {
		t.Fatalf("DeleteProjectMembership() error = %v", err)
	}

	// Verify deleted
	_, err = repo.GetProjectMembership(ctx, "proj-1", "user-1")
	if err != repository.ErrNotFound {
		t.Errorf("GetProjectMembership() after delete error = %v, want ErrNotFound", err)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository_Project -v`
Expected: FAIL with method not defined

**Step 3: Write minimal implementation**

```go
// Add to internal/repository/memory/permissions_repository.go

func (r *PermissionsRepository) projectMembershipKey(projectID, userID string) string {
	return projectID + "/" + userID
}

// CreateProjectMembership creates a new project membership
func (r *PermissionsRepository) CreateProjectMembership(ctx context.Context, m *domain.ProjectMembership) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.projectMembershipKey(m.ProjectID, m.UserID)
	if _, exists := r.projectMemberships[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *m
	r.projectMemberships[key] = &copy
	return nil
}

// GetProjectMembership retrieves a project membership by project and user ID
func (r *PermissionsRepository) GetProjectMembership(ctx context.Context, projectID, userID string) (*domain.ProjectMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := r.projectMembershipKey(projectID, userID)
	m, exists := r.projectMemberships[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *m
	return &copy, nil
}

// ListProjectMemberships returns all memberships for a project
func (r *PermissionsRepository) ListProjectMemberships(ctx context.Context, projectID string) ([]*domain.ProjectMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.ProjectMembership
	for _, m := range r.projectMemberships {
		if m.ProjectID == projectID {
			copy := *m
			result = append(result, &copy)
		}
	}
	return result, nil
}

// ListUserProjectMemberships returns all project memberships for a user
func (r *PermissionsRepository) ListUserProjectMemberships(ctx context.Context, userID string) ([]*domain.ProjectMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.ProjectMembership
	for _, m := range r.projectMemberships {
		if m.UserID == userID {
			copy := *m
			result = append(result, &copy)
		}
	}
	return result, nil
}

// UpdateProjectMembership updates an existing project membership
func (r *PermissionsRepository) UpdateProjectMembership(ctx context.Context, m *domain.ProjectMembership) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.projectMembershipKey(m.ProjectID, m.UserID)
	if _, exists := r.projectMemberships[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *m
	r.projectMemberships[key] = &copy
	return nil
}

// DeleteProjectMembership removes a project membership
func (r *PermissionsRepository) DeleteProjectMembership(ctx context.Context, projectID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.projectMembershipKey(projectID, userID)
	if _, exists := r.projectMemberships[key]; !exists {
		return repository.ErrNotFound
	}

	delete(r.projectMemberships, key)
	return nil
}

// CountProjectOwners returns the number of owners for a project
func (r *PermissionsRepository) CountProjectOwners(ctx context.Context, projectID string) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	count := 0
	for _, m := range r.projectMemberships {
		if m.ProjectID == projectID && m.Role == domain.ProjectRoleOwner {
			count++
		}
	}
	return count, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository_Project -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/permissions_repository.go internal/repository/memory/permissions_repository_test.go
git commit -m "feat(permissions): add project membership repository methods"
```

---

## Task 2: Create Project Permissions Service

**Files:**
- Create: `internal/service/project_permissions_service.go`
- Create: `internal/service/project_permissions_service_test.go`

**Step 1: Write the failing test**

```go
// internal/service/project_permissions_service_test.go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func TestProjectPermissionsService_AddMember(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewProjectPermissionsService(repo)
	ctx := context.Background()

	// Add first member as owner
	input := AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	}

	membership, err := svc.AddMember(ctx, input)
	if err != nil {
		t.Fatalf("AddMember() error = %v", err)
	}

	if membership.Role != domain.ProjectRoleOwner {
		t.Errorf("Role = %v, want owner", membership.Role)
	}

	// Add another member
	input2 := AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "user-1",
	}

	membership2, err := svc.AddMember(ctx, input2)
	if err != nil {
		t.Fatalf("AddMember() second error = %v", err)
	}

	if membership2.Role != domain.ProjectRoleEditor {
		t.Errorf("Role = %v, want editor", membership2.Role)
	}
}

func TestProjectPermissionsService_UpdateRole(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewProjectPermissionsService(repo)
	ctx := context.Background()

	// Setup: add owner and editor
	_, _ = svc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	})
	_, _ = svc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "user-1",
	})

	// Promote editor to owner
	input := UpdateProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleOwner,
	}

	membership, err := svc.UpdateRole(ctx, input)
	if err != nil {
		t.Fatalf("UpdateRole() error = %v", err)
	}

	if membership.Role != domain.ProjectRoleOwner {
		t.Errorf("Role = %v, want owner", membership.Role)
	}
}

func TestProjectPermissionsService_RemoveMember_LastOwner(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewProjectPermissionsService(repo)
	ctx := context.Background()

	// Add single owner
	_, _ = svc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	})

	// Try to remove the only owner - should fail
	err := svc.RemoveMember(ctx, "proj-1", "user-1")
	if err != ErrLastOwner {
		t.Errorf("RemoveMember() last owner error = %v, want ErrLastOwner", err)
	}

	// Add second owner
	_, _ = svc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "user-1",
	})

	// Now removing first owner should succeed
	err = svc.RemoveMember(ctx, "proj-1", "user-1")
	if err != nil {
		t.Errorf("RemoveMember() with backup owner error = %v", err)
	}
}

func TestProjectPermissionsService_CanUserActAs(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewProjectPermissionsService(repo)
	ctx := context.Background()

	// Add editor
	_, _ = svc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "system",
	})

	// Editor can act as approver
	can, err := svc.CanUserActAs(ctx, "proj-1", "user-1", domain.ProjectRoleApprover)
	if err != nil {
		t.Fatalf("CanUserActAs() error = %v", err)
	}
	if !can {
		t.Error("Editor should be able to act as Approver")
	}

	// Editor cannot act as owner
	can, err = svc.CanUserActAs(ctx, "proj-1", "user-1", domain.ProjectRoleOwner)
	if err != nil {
		t.Fatalf("CanUserActAs() error = %v", err)
	}
	if can {
		t.Error("Editor should NOT be able to act as Owner")
	}

	// Non-member cannot act
	can, err = svc.CanUserActAs(ctx, "proj-1", "user-999", domain.ProjectRoleViewer)
	if err != nil {
		t.Fatalf("CanUserActAs() error = %v", err)
	}
	if can {
		t.Error("Non-member should NOT be able to act")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run TestProjectPermissionsService -v`
Expected: FAIL with "undefined: NewProjectPermissionsService"

**Step 3: Write minimal implementation**

```go
// internal/service/project_permissions_service.go
package service

import (
	"context"
	"errors"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

var (
	ErrLastOwner = errors.New("cannot remove the last owner")
)

// ProjectPermissionsService handles project permission business logic
type ProjectPermissionsService struct {
	repo repository.PermissionsRepository
}

// NewProjectPermissionsService creates a new project permissions service
func NewProjectPermissionsService(repo repository.PermissionsRepository) *ProjectPermissionsService {
	return &ProjectPermissionsService{repo: repo}
}

// AddProjectMemberInput contains fields for adding a project member
type AddProjectMemberInput struct {
	ProjectID string
	UserID    string
	Role      domain.ProjectRole
	AddedBy   string
}

// UpdateProjectMemberInput contains fields for updating a member's role
type UpdateProjectMemberInput struct {
	ProjectID string
	UserID    string
	Role      domain.ProjectRole
}

// AddMember adds a new member to a project
func (s *ProjectPermissionsService) AddMember(ctx context.Context, input AddProjectMemberInput) (*domain.ProjectMembership, error) {
	if !input.Role.IsValid() {
		return nil, errors.New("invalid role")
	}

	membership := &domain.ProjectMembership{
		ID:        generateProjectMembershipID(),
		ProjectID: input.ProjectID,
		UserID:    input.UserID,
		Role:      input.Role,
		AddedBy:   input.AddedBy,
		AddedAt:   time.Now(),
	}

	if err := membership.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateProjectMembership(ctx, membership); err != nil {
		return nil, err
	}

	return membership, nil
}

// GetMember retrieves a project member
func (s *ProjectPermissionsService) GetMember(ctx context.Context, projectID, userID string) (*domain.ProjectMembership, error) {
	return s.repo.GetProjectMembership(ctx, projectID, userID)
}

// ListMembers returns all members of a project
func (s *ProjectPermissionsService) ListMembers(ctx context.Context, projectID string) ([]*domain.ProjectMembership, error) {
	return s.repo.ListProjectMemberships(ctx, projectID)
}

// UpdateRole updates a member's role in a project
func (s *ProjectPermissionsService) UpdateRole(ctx context.Context, input UpdateProjectMemberInput) (*domain.ProjectMembership, error) {
	if !input.Role.IsValid() {
		return nil, errors.New("invalid role")
	}

	membership, err := s.repo.GetProjectMembership(ctx, input.ProjectID, input.UserID)
	if err != nil {
		return nil, err
	}

	// If demoting from owner, check if this is the last owner
	if membership.Role == domain.ProjectRoleOwner && input.Role != domain.ProjectRoleOwner {
		count, err := s.repo.CountProjectOwners(ctx, input.ProjectID)
		if err != nil {
			return nil, err
		}
		if count <= 1 {
			return nil, ErrLastOwner
		}
	}

	membership.Role = input.Role

	if err := s.repo.UpdateProjectMembership(ctx, membership); err != nil {
		return nil, err
	}

	return membership, nil
}

// RemoveMember removes a member from a project
func (s *ProjectPermissionsService) RemoveMember(ctx context.Context, projectID, userID string) error {
	membership, err := s.repo.GetProjectMembership(ctx, projectID, userID)
	if err != nil {
		return err
	}

	// Check if this is the last owner
	if membership.Role == domain.ProjectRoleOwner {
		count, err := s.repo.CountProjectOwners(ctx, projectID)
		if err != nil {
			return err
		}
		if count <= 1 {
			return ErrLastOwner
		}
	}

	return s.repo.DeleteProjectMembership(ctx, projectID, userID)
}

// CanUserActAs checks if a user has at least the specified role level
func (s *ProjectPermissionsService) CanUserActAs(ctx context.Context, projectID, userID string, requiredRole domain.ProjectRole) (bool, error) {
	membership, err := s.repo.GetProjectMembership(ctx, projectID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			return false, nil
		}
		return false, err
	}

	return membership.Role.CanActAs(requiredRole), nil
}

// ListUserProjects returns all projects a user has access to
func (s *ProjectPermissionsService) ListUserProjects(ctx context.Context, userID string) ([]*domain.ProjectMembership, error) {
	return s.repo.ListUserProjectMemberships(ctx, userID)
}

func generateProjectMembershipID() string {
	return "pm-" + randomString(12)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run TestProjectPermissionsService -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/project_permissions_service.go internal/service/project_permissions_service_test.go
git commit -m "feat(permissions): add project permissions service"
```

---

## Task 3: Create Project Members HTTP Handler

**Files:**
- Create: `internal/api/handlers/project_members.go`
- Create: `internal/api/handlers/project_members_test.go`

**Step 1: Write the failing test**

```go
// internal/api/handlers/project_members_test.go
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

func TestProjectMembersHandler_Add(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewProjectPermissionsService(repo)
	handler := NewProjectMembersHandler(svc)

	reqBody := AddProjectMemberRequest{
		UserID: "user-1",
		Role:   domain.ProjectRoleOwner,
	}
	body, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/orgs/org-1/projects/proj-1/members", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "admin-1")
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	rctx.URLParams.Add("projectID", "proj-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Add(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %d, want %d. Body: %s", w.Code, http.StatusCreated, w.Body.String())
	}

	var resp domain.ProjectMembership
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.Role != domain.ProjectRoleOwner {
		t.Errorf("Role = %s, want owner", resp.Role)
	}
}

func TestProjectMembersHandler_List(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewProjectPermissionsService(repo)
	handler := NewProjectMembersHandler(svc)

	// Add some members
	ctx := context.Background()
	_, _ = svc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	})
	_, _ = svc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "user-1",
	})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/orgs/org-1/projects/proj-1/members", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	rctx.URLParams.Add("projectID", "proj-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.List(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
	}

	var resp []*domain.ProjectMembership
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if len(resp) != 2 {
		t.Errorf("Member count = %d, want 2", len(resp))
	}
}

func TestProjectMembersHandler_Update(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewProjectPermissionsService(repo)
	handler := NewProjectMembersHandler(svc)

	// Add a member
	ctx := context.Background()
	_, _ = svc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	})
	_, _ = svc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-2",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "user-1",
	})

	// Update role
	reqBody := UpdateProjectMemberRequest{
		Role: domain.ProjectRoleOwner,
	}
	body, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/orgs/org-1/projects/proj-1/members/user-2", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	rctx.URLParams.Add("projectID", "proj-1")
	rctx.URLParams.Add("userID", "user-2")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Update(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d. Body: %s", w.Code, http.StatusOK, w.Body.String())
	}

	var resp domain.ProjectMembership
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.Role != domain.ProjectRoleOwner {
		t.Errorf("Role = %s, want owner", resp.Role)
	}
}

func TestProjectMembersHandler_Remove_LastOwner(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewProjectPermissionsService(repo)
	handler := NewProjectMembersHandler(svc)

	// Add single owner
	ctx := context.Background()
	_, _ = svc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "user-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "system",
	})

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/orgs/org-1/projects/proj-1/members/user-1", nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", "org-1")
	rctx.URLParams.Add("projectID", "proj-1")
	rctx.URLParams.Add("userID", "user-1")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Remove(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("Status = %d, want %d (should fail for last owner)", w.Code, http.StatusBadRequest)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -run TestProjectMembersHandler -v`
Expected: FAIL with "undefined: NewProjectMembersHandler"

**Step 3: Write minimal implementation**

```go
// internal/api/handlers/project_members.go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

// ProjectMembersHandler handles project membership HTTP requests
type ProjectMembersHandler struct {
	svc *service.ProjectPermissionsService
}

// NewProjectMembersHandler creates a new project members handler
func NewProjectMembersHandler(svc *service.ProjectPermissionsService) *ProjectMembersHandler {
	return &ProjectMembersHandler{svc: svc}
}

// AddProjectMemberRequest is the request body for adding a project member
type AddProjectMemberRequest struct {
	UserID string             `json:"userId"`
	Role   domain.ProjectRole `json:"role"`
}

// UpdateProjectMemberRequest is the request body for updating a project member's role
type UpdateProjectMemberRequest struct {
	Role domain.ProjectRole `json:"role"`
}

// List handles GET /api/v1/orgs/{orgID}/projects/{projectID}/members
func (h *ProjectMembersHandler) List(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")

	members, err := h.svc.ListMembers(r.Context(), projectID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if members == nil {
		members = []*domain.ProjectMembership{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(members)
}

// Add handles POST /api/v1/orgs/{orgID}/projects/{projectID}/members
func (h *ProjectMembersHandler) Add(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	addedBy := r.Header.Get("X-User-ID")
	if addedBy == "" {
		addedBy = "system"
	}

	var req AddProjectMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.AddProjectMemberInput{
		ProjectID: projectID,
		UserID:    req.UserID,
		Role:      req.Role,
		AddedBy:   addedBy,
	}

	membership, err := h.svc.AddMember(r.Context(), input)
	if err != nil {
		if err == repository.ErrAlreadyExists {
			http.Error(w, "member already exists", http.StatusConflict)
			return
		}
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(membership)
}

// Get handles GET /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}
func (h *ProjectMembersHandler) Get(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	userID := chi.URLParam(r, "userID")

	membership, err := h.svc.GetMember(r.Context(), projectID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "member not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(membership)
}

// Update handles PUT /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}
func (h *ProjectMembersHandler) Update(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	userID := chi.URLParam(r, "userID")

	var req UpdateProjectMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.UpdateProjectMemberInput{
		ProjectID: projectID,
		UserID:    userID,
		Role:      req.Role,
	}

	membership, err := h.svc.UpdateRole(r.Context(), input)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "member not found", http.StatusNotFound)
			return
		}
		if err == service.ErrLastOwner {
			http.Error(w, "cannot demote the last owner", http.StatusBadRequest)
			return
		}
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(membership)
}

// Remove handles DELETE /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}
func (h *ProjectMembersHandler) Remove(w http.ResponseWriter, r *http.Request) {
	projectID := chi.URLParam(r, "projectID")
	userID := chi.URLParam(r, "userID")

	err := h.svc.RemoveMember(r.Context(), projectID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "member not found", http.StatusNotFound)
			return
		}
		if err == service.ErrLastOwner {
			http.Error(w, "cannot remove the last owner", http.StatusBadRequest)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/api/handlers/... -run TestProjectMembersHandler -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/project_members.go internal/api/handlers/project_members_test.go
git commit -m "feat(permissions): add project members HTTP handler"
```

---

## Task 4: Register Project Member Routes

**Files:**
- Modify: `internal/api/routes/routes.go`

**Step 1: Read current routes**

Check the current routes setup.

**Step 2: Add project member routes**

Add to the Setup function:

```go
// In Setup function, add project permissions service and handler
projectPermsSvc := service.NewProjectPermissionsService(permissionsRepo)
projectMembersHandler := handlers.NewProjectMembersHandler(projectPermsSvc)

// Add routes under the org route group
r.Route("/api/v1", func(r chi.Router) {
	r.Route("/orgs", func(r chi.Router) {
		// ... existing org routes

		r.Route("/{orgID}", func(r chi.Router) {
			// ... existing org member routes

			// Project member routes
			r.Route("/projects/{projectID}/members", func(r chi.Router) {
				r.Get("/", projectMembersHandler.List)
				r.Post("/", projectMembersHandler.Add)
				r.Get("/{userID}", projectMembersHandler.Get)
				r.Put("/{userID}", projectMembersHandler.Update)
				r.Delete("/{userID}", projectMembersHandler.Remove)
			})

			// ... existing knowledge routes
		})
	})
})
```

**Step 3: Run build to verify compilation**

Run: `go build ./...`
Expected: No errors

**Step 4: Commit**

```bash
git add internal/api/routes/routes.go
git commit -m "feat(permissions): register project member routes"
```

---

## Task 5: Run All Tests

**Step 1: Run all tests**

Run: `go test ./internal/... -v`
Expected: All tests PASS

**Step 2: Run linter**

Run: `go vet ./internal/...`
Expected: No errors

**Step 3: Final commit for part 3**

```bash
git add -A
git commit -m "feat(permissions): complete project permissions implementation

- Add project membership repository methods
- Add ProjectPermissionsService with role management
- Implement role hierarchy (Owner > Editor > Approver > Viewer)
- Add HTTP handlers for project members
- Enforce at least one Owner per project
- Register project member routes"
```

---

## Summary

After completing Part 3, you will have:

**Modified Files:**
- `internal/repository/memory/permissions_repository.go` - Added project membership methods
- `internal/repository/memory/permissions_repository_test.go` - Added tests
- `internal/api/routes/routes.go` - Added project member routes

**Created Files:**
- `internal/service/project_permissions_service.go` - Project permissions service
- `internal/service/project_permissions_service_test.go` - Service tests
- `internal/api/handlers/project_members.go` - HTTP handlers
- `internal/api/handlers/project_members_test.go` - Handler tests

**API Endpoints:**
- `GET /api/v1/orgs/{orgID}/projects/{projectID}/members` - List project members
- `POST /api/v1/orgs/{orgID}/projects/{projectID}/members` - Add project member
- `GET /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}` - Get member
- `PUT /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}` - Update role
- `DELETE /api/v1/orgs/{orgID}/projects/{projectID}/members/{userID}` - Remove member

**Business Rules Enforced:**
- At least one Owner required per project
- Role hierarchy checked via `CanActAs()` method
- Last Owner cannot be removed or demoted

**Next:** Proceed to [04-authorization-middleware.md](./04-authorization-middleware.md)
