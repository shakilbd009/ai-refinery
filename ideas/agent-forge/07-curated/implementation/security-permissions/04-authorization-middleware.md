# Part 4: Authorization Middleware

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement permission checking middleware with admin override and cross-org prevention.

**Architecture:** Chi middleware functions that check permissions before handlers execute. Support for org-level and project-level permission checks. Admin users can access any resource in their org.

**Tech Stack:** Go, Chi router middleware

**Prerequisite:** Complete [03-project-permissions.md](./03-project-permissions.md) first.

---

## Task 1: Create Authorization Service

**Files:**
- Create: `internal/service/auth_service.go`
- Create: `internal/service/auth_service_test.go`

**Step 1: Write the failing test**

```go
// internal/service/auth_service_test.go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func setupAuthTestData(t *testing.T) (*AuthService, *memory.PermissionsRepository) {
	repo := memory.NewPermissionsRepository()
	orgSvc := NewOrgService(repo)
	projectPermsSvc := NewProjectPermissionsService(repo)
	authSvc := NewAuthService(repo, orgSvc, projectPermsSvc)
	ctx := context.Background()

	// Create org with admin
	org, _ := orgSvc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	// Add regular member
	_, _ = orgSvc.AddMember(ctx, AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "member-1",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	})

	// Add project lead
	_, _ = orgSvc.AddMember(ctx, AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "lead-1",
		Role:      domain.OrgRoleProjectLead,
		InvitedBy: "admin-1",
	})

	// Create project with owner
	_, _ = projectPermsSvc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "owner-1",
		Role:      domain.ProjectRoleOwner,
		AddedBy:   "admin-1",
	})

	// Add editor to project
	_, _ = projectPermsSvc.AddMember(ctx, AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "member-1",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "owner-1",
	})

	return authSvc, repo
}

func TestAuthService_HasOrgRole(t *testing.T) {
	authSvc, repo := setupAuthTestData(t)
	ctx := context.Background()

	// Get the org ID
	memberships, _ := repo.ListUserOrgMemberships(ctx, "admin-1")
	orgID := memberships[0].OrgID

	tests := []struct {
		name     string
		userID   string
		orgID    string
		role     domain.OrgRole
		expected bool
	}{
		{"admin has admin role", "admin-1", orgID, domain.OrgRoleAdmin, true},
		{"admin can act as member", "admin-1", orgID, domain.OrgRoleMember, true},
		{"member has member role", "member-1", orgID, domain.OrgRoleMember, true},
		{"member does not have admin role", "member-1", orgID, domain.OrgRoleAdmin, false},
		{"lead has lead role", "lead-1", orgID, domain.OrgRoleProjectLead, true},
		{"non-member has no role", "stranger", orgID, domain.OrgRoleMember, false},
		{"wrong org returns false", "admin-1", "wrong-org", domain.OrgRoleAdmin, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			has, err := authSvc.HasOrgRole(ctx, tt.userID, tt.orgID, tt.role)
			if err != nil {
				t.Fatalf("HasOrgRole() error = %v", err)
			}
			if has != tt.expected {
				t.Errorf("HasOrgRole() = %v, want %v", has, tt.expected)
			}
		})
	}
}

func TestAuthService_HasProjectRole(t *testing.T) {
	authSvc, repo := setupAuthTestData(t)
	ctx := context.Background()

	// Get the org ID for admin override test
	memberships, _ := repo.ListUserOrgMemberships(ctx, "admin-1")
	orgID := memberships[0].OrgID

	tests := []struct {
		name     string
		userID   string
		orgID    string
		projID   string
		role     domain.ProjectRole
		expected bool
	}{
		{"owner has owner role", "owner-1", orgID, "proj-1", domain.ProjectRoleOwner, true},
		{"owner can act as editor", "owner-1", orgID, "proj-1", domain.ProjectRoleEditor, true},
		{"editor has editor role", "member-1", orgID, "proj-1", domain.ProjectRoleEditor, true},
		{"editor can act as viewer", "member-1", orgID, "proj-1", domain.ProjectRoleViewer, true},
		{"editor cannot act as owner", "member-1", orgID, "proj-1", domain.ProjectRoleOwner, false},
		{"admin override - can access any project", "admin-1", orgID, "proj-1", domain.ProjectRoleOwner, true},
		{"non-member has no role", "stranger", orgID, "proj-1", domain.ProjectRoleViewer, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			has, err := authSvc.HasProjectRole(ctx, tt.userID, tt.orgID, tt.projID, tt.role)
			if err != nil {
				t.Fatalf("HasProjectRole() error = %v", err)
			}
			if has != tt.expected {
				t.Errorf("HasProjectRole() = %v, want %v", has, tt.expected)
			}
		})
	}
}

func TestAuthService_IsOrgMember(t *testing.T) {
	authSvc, repo := setupAuthTestData(t)
	ctx := context.Background()

	memberships, _ := repo.ListUserOrgMemberships(ctx, "admin-1")
	orgID := memberships[0].OrgID

	// Member of org
	isMember, err := authSvc.IsOrgMember(ctx, "member-1", orgID)
	if err != nil {
		t.Fatalf("IsOrgMember() error = %v", err)
	}
	if !isMember {
		t.Error("member-1 should be member of org")
	}

	// Non-member
	isMember, err = authSvc.IsOrgMember(ctx, "stranger", orgID)
	if err != nil {
		t.Fatalf("IsOrgMember() error = %v", err)
	}
	if isMember {
		t.Error("stranger should NOT be member of org")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run TestAuthService -v`
Expected: FAIL with "undefined: NewAuthService"

**Step 3: Write minimal implementation**

```go
// internal/service/auth_service.go
package service

import (
	"context"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// AuthService handles authorization checks
type AuthService struct {
	repo            repository.PermissionsRepository
	orgSvc          *OrgService
	projectPermsSvc *ProjectPermissionsService
}

// NewAuthService creates a new authorization service
func NewAuthService(
	repo repository.PermissionsRepository,
	orgSvc *OrgService,
	projectPermsSvc *ProjectPermissionsService,
) *AuthService {
	return &AuthService{
		repo:            repo,
		orgSvc:          orgSvc,
		projectPermsSvc: projectPermsSvc,
	}
}

// IsOrgMember checks if a user is a member of an organization
func (s *AuthService) IsOrgMember(ctx context.Context, userID, orgID string) (bool, error) {
	_, err := s.repo.GetOrgMembership(ctx, orgID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// HasOrgRole checks if a user has at least the specified org role
func (s *AuthService) HasOrgRole(ctx context.Context, userID, orgID string, requiredRole domain.OrgRole) (bool, error) {
	membership, err := s.repo.GetOrgMembership(ctx, orgID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			return false, nil
		}
		return false, err
	}

	return s.canOrgRoleActAs(membership.Role, requiredRole), nil
}

// HasProjectRole checks if a user has at least the specified project role
// Admin users can access any project in their org (admin override)
func (s *AuthService) HasProjectRole(ctx context.Context, userID, orgID, projectID string, requiredRole domain.ProjectRole) (bool, error) {
	// First check if user is org admin (admin override)
	isAdmin, err := s.HasOrgRole(ctx, userID, orgID, domain.OrgRoleAdmin)
	if err != nil {
		return false, err
	}
	if isAdmin {
		return true, nil // Admin can access any project as any role
	}

	// Check project-level permission
	return s.projectPermsSvc.CanUserActAs(ctx, projectID, userID, requiredRole)
}

// GetUserOrgRole returns the user's role in an organization, if any
func (s *AuthService) GetUserOrgRole(ctx context.Context, userID, orgID string) (domain.OrgRole, error) {
	membership, err := s.repo.GetOrgMembership(ctx, orgID, userID)
	if err != nil {
		return "", err
	}
	return membership.Role, nil
}

// GetUserProjectRole returns the user's role in a project, if any
func (s *AuthService) GetUserProjectRole(ctx context.Context, userID, projectID string) (domain.ProjectRole, error) {
	membership, err := s.repo.GetProjectMembership(ctx, projectID, userID)
	if err != nil {
		return "", err
	}
	return membership.Role, nil
}

// canOrgRoleActAs checks if an org role can act as another role
// Admin > SME Curator = Project Lead > Member
func (s *AuthService) canOrgRoleActAs(role, requiredRole domain.OrgRole) bool {
	roleLevel := s.orgRoleLevel(role)
	requiredLevel := s.orgRoleLevel(requiredRole)
	return roleLevel >= requiredLevel
}

func (s *AuthService) orgRoleLevel(role domain.OrgRole) int {
	switch role {
	case domain.OrgRoleAdmin:
		return 4
	case domain.OrgRoleSMECurator:
		return 3
	case domain.OrgRoleProjectLead:
		return 3
	case domain.OrgRoleMember:
		return 1
	}
	return 0
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run TestAuthService -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/auth_service.go internal/service/auth_service_test.go
git commit -m "feat(permissions): add authorization service with admin override"
```

---

## Task 2: Create Permission Middleware

**Files:**
- Create: `internal/api/middleware/permissions.go`
- Create: `internal/api/middleware/permissions_test.go`

**Step 1: Write the failing test**

```go
// internal/api/middleware/permissions_test.go
package middleware

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
	"github.com/anthropics/agentic-platform/internal/service"
)

func setupMiddlewareTest(t *testing.T) (*PermissionsMiddleware, string) {
	repo := memory.NewPermissionsRepository()
	orgSvc := service.NewOrgService(repo)
	projectPermsSvc := service.NewProjectPermissionsService(repo)
	authSvc := service.NewAuthService(repo, orgSvc, projectPermsSvc)

	ctx := context.Background()

	// Create org with admin
	org, _ := orgSvc.CreateOrganization(ctx, service.CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	// Add regular member
	_, _ = orgSvc.AddMember(ctx, service.AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "member-1",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	})

	// Add SME curator
	_, _ = orgSvc.AddMember(ctx, service.AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "curator-1",
		Role:      domain.OrgRoleSMECurator,
		InvitedBy: "admin-1",
	})

	// Add project with editor
	_, _ = projectPermsSvc.AddMember(ctx, service.AddProjectMemberInput{
		ProjectID: "proj-1",
		UserID:    "editor-1",
		Role:      domain.ProjectRoleEditor,
		AddedBy:   "admin-1",
	})

	mw := NewPermissionsMiddleware(authSvc)
	return mw, org.ID
}

func TestPermissionsMiddleware_RequireOrgMembership(t *testing.T) {
	mw, orgID := setupMiddlewareTest(t)

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	tests := []struct {
		name       string
		userID     string
		orgID      string
		wantStatus int
	}{
		{"member can access", "member-1", orgID, http.StatusOK},
		{"admin can access", "admin-1", orgID, http.StatusOK},
		{"non-member blocked", "stranger", orgID, http.StatusForbidden},
		{"wrong org blocked", "member-1", "wrong-org", http.StatusForbidden},
		{"no user header", "", orgID, http.StatusUnauthorized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			if tt.userID != "" {
				req.Header.Set("X-User-ID", tt.userID)
			}
			rctx := chi.NewRouteContext()
			rctx.URLParams.Add("orgID", tt.orgID)
			req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

			w := httptest.NewRecorder()
			mw.RequireOrgMembership(handler).ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}
		})
	}
}

func TestPermissionsMiddleware_RequireOrgRole(t *testing.T) {
	mw, orgID := setupMiddlewareTest(t)

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	tests := []struct {
		name       string
		userID     string
		role       domain.OrgRole
		wantStatus int
	}{
		{"admin has admin role", "admin-1", domain.OrgRoleAdmin, http.StatusOK},
		{"curator has curator role", "curator-1", domain.OrgRoleSMECurator, http.StatusOK},
		{"member lacks admin role", "member-1", domain.OrgRoleAdmin, http.StatusForbidden},
		{"member has member role", "member-1", domain.OrgRoleMember, http.StatusOK},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			req.Header.Set("X-User-ID", tt.userID)
			rctx := chi.NewRouteContext()
			rctx.URLParams.Add("orgID", orgID)
			req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

			w := httptest.NewRecorder()
			mw.RequireOrgRole(tt.role)(handler).ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}
		})
	}
}

func TestPermissionsMiddleware_RequireProjectRole(t *testing.T) {
	mw, orgID := setupMiddlewareTest(t)

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	tests := []struct {
		name       string
		userID     string
		role       domain.ProjectRole
		wantStatus int
	}{
		{"editor has editor role", "editor-1", domain.ProjectRoleEditor, http.StatusOK},
		{"editor can act as viewer", "editor-1", domain.ProjectRoleViewer, http.StatusOK},
		{"editor lacks owner role", "editor-1", domain.ProjectRoleOwner, http.StatusForbidden},
		{"admin override works", "admin-1", domain.ProjectRoleOwner, http.StatusOK},
		{"non-member blocked", "stranger", domain.ProjectRoleViewer, http.StatusForbidden},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			req.Header.Set("X-User-ID", tt.userID)
			rctx := chi.NewRouteContext()
			rctx.URLParams.Add("orgID", orgID)
			rctx.URLParams.Add("projectID", "proj-1")
			req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

			w := httptest.NewRecorder()
			mw.RequireProjectRole(tt.role)(handler).ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("Status = %d, want %d", w.Code, tt.wantStatus)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/middleware/... -run TestPermissionsMiddleware -v`
Expected: FAIL with "undefined: NewPermissionsMiddleware"

**Step 3: Write minimal implementation**

```go
// internal/api/middleware/permissions.go
package middleware

import (
	"context"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/service"
)

// Context keys for user information
type contextKey string

const (
	UserIDKey  contextKey = "userID"
	OrgIDKey   contextKey = "orgID"
	OrgRoleKey contextKey = "orgRole"
)

// PermissionsMiddleware provides authorization middleware functions
type PermissionsMiddleware struct {
	authSvc *service.AuthService
}

// NewPermissionsMiddleware creates a new permissions middleware
func NewPermissionsMiddleware(authSvc *service.AuthService) *PermissionsMiddleware {
	return &PermissionsMiddleware{authSvc: authSvc}
}

// RequireAuth extracts and validates the user ID from the request header
func (m *PermissionsMiddleware) RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := r.Header.Get("X-User-ID")
		if userID == "" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}

		// Add user ID to context
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireOrgMembership checks that the user is a member of the organization
func (m *PermissionsMiddleware) RequireOrgMembership(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := r.Header.Get("X-User-ID")
		if userID == "" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}

		orgID := chi.URLParam(r, "orgID")
		if orgID == "" {
			http.Error(w, "org ID required", http.StatusBadRequest)
			return
		}

		isMember, err := m.authSvc.IsOrgMember(r.Context(), userID, orgID)
		if err != nil {
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		if !isMember {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}

		// Add to context
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		ctx = context.WithValue(ctx, OrgIDKey, orgID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireOrgRole checks that the user has at least the specified org role
func (m *PermissionsMiddleware) RequireOrgRole(requiredRole domain.OrgRole) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID := r.Header.Get("X-User-ID")
			if userID == "" {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			orgID := chi.URLParam(r, "orgID")
			if orgID == "" {
				http.Error(w, "org ID required", http.StatusBadRequest)
				return
			}

			hasRole, err := m.authSvc.HasOrgRole(r.Context(), userID, orgID, requiredRole)
			if err != nil {
				http.Error(w, "internal error", http.StatusInternalServerError)
				return
			}

			if !hasRole {
				http.Error(w, "forbidden", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), UserIDKey, userID)
			ctx = context.WithValue(ctx, OrgIDKey, orgID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireProjectRole checks that the user has at least the specified project role
// Org admins bypass this check (admin override)
func (m *PermissionsMiddleware) RequireProjectRole(requiredRole domain.ProjectRole) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID := r.Header.Get("X-User-ID")
			if userID == "" {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			orgID := chi.URLParam(r, "orgID")
			projectID := chi.URLParam(r, "projectID")

			if orgID == "" || projectID == "" {
				http.Error(w, "org ID and project ID required", http.StatusBadRequest)
				return
			}

			hasRole, err := m.authSvc.HasProjectRole(r.Context(), userID, orgID, projectID, requiredRole)
			if err != nil {
				http.Error(w, "internal error", http.StatusInternalServerError)
				return
			}

			if !hasRole {
				http.Error(w, "forbidden", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), UserIDKey, userID)
			ctx = context.WithValue(ctx, OrgIDKey, orgID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// GetUserID extracts user ID from context
func GetUserID(ctx context.Context) string {
	if v := ctx.Value(UserIDKey); v != nil {
		return v.(string)
	}
	return ""
}

// GetOrgID extracts org ID from context
func GetOrgID(ctx context.Context) string {
	if v := ctx.Value(OrgIDKey); v != nil {
		return v.(string)
	}
	return ""
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/api/middleware/... -run TestPermissionsMiddleware -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/middleware/permissions.go internal/api/middleware/permissions_test.go
git commit -m "feat(permissions): add authorization middleware with admin override"
```

---

## Task 3: Apply Middleware to Routes

**Files:**
- Modify: `internal/api/routes/routes.go`

**Step 1: Read current routes file**

Check current route structure.

**Step 2: Update routes to use permission middleware**

```go
// Updated routes.go
package routes

import (
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"

	"github.com/anthropics/agentic-platform/internal/api/handlers"
	"github.com/anthropics/agentic-platform/internal/api/middleware"
	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

// Setup creates and configures the router with all routes
func Setup(
	knowledgeRepo repository.KnowledgeRepository,
	workflowRepo repository.WorkflowRepository,
	permissionsRepo repository.PermissionsRepository,
) *chi.Mux {
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(chimiddleware.RequestID)

	// Services
	knowledgeSvc := service.NewKnowledgeService(knowledgeRepo)
	workflowSvc := service.NewWorkflowService(workflowRepo, knowledgeRepo)
	orgSvc := service.NewOrgService(permissionsRepo)
	projectPermsSvc := service.NewProjectPermissionsService(permissionsRepo)
	authSvc := service.NewAuthService(permissionsRepo, orgSvc, projectPermsSvc)

	// Handlers
	guidelinesHandler := handlers.NewGuidelinesHandler(knowledgeSvc)
	templatesHandler := handlers.NewTemplatesHandler(knowledgeSvc)
	examplesHandler := handlers.NewExamplesHandler(knowledgeSvc)
	constraintsHandler := handlers.NewConstraintsHandler(knowledgeSvc)
	workflowsHandler := handlers.NewWorkflowsHandler(workflowSvc)
	orgsHandler := handlers.NewOrganizationsHandler(orgSvc)
	projectMembersHandler := handlers.NewProjectMembersHandler(projectPermsSvc)

	// Permission middleware
	permMW := middleware.NewPermissionsMiddleware(authSvc)

	r.Route("/api/v1", func(r chi.Router) {
		// Organization routes (requires auth)
		r.Route("/orgs", func(r chi.Router) {
			r.Post("/", orgsHandler.Create) // Anyone authenticated can create an org

			r.Route("/{orgID}", func(r chi.Router) {
				// All routes under org require org membership
				r.Use(permMW.RequireOrgMembership)

				r.Get("/", orgsHandler.Get)

				// Member management (requires admin)
				r.Route("/members", func(r chi.Router) {
					r.Get("/", orgsHandler.ListMembers)
					r.With(permMW.RequireOrgRole(domain.OrgRoleAdmin)).Post("/", orgsHandler.AddMember)
					r.Get("/{userID}", orgsHandler.GetMember)
					r.With(permMW.RequireOrgRole(domain.OrgRoleAdmin)).Put("/{userID}", orgsHandler.UpdateMember)
					r.With(permMW.RequireOrgRole(domain.OrgRoleAdmin)).Delete("/{userID}", orgsHandler.RemoveMember)
				})

				// Project member routes
				r.Route("/projects/{projectID}/members", func(r chi.Router) {
					r.With(permMW.RequireProjectRole(domain.ProjectRoleViewer)).Get("/", projectMembersHandler.List)
					r.With(permMW.RequireProjectRole(domain.ProjectRoleOwner)).Post("/", projectMembersHandler.Add)
					r.With(permMW.RequireProjectRole(domain.ProjectRoleViewer)).Get("/{userID}", projectMembersHandler.Get)
					r.With(permMW.RequireProjectRole(domain.ProjectRoleOwner)).Put("/{userID}", projectMembersHandler.Update)
					r.With(permMW.RequireProjectRole(domain.ProjectRoleOwner)).Delete("/{userID}", projectMembersHandler.Remove)
				})

				// Knowledge routes (requires SME Curator or Admin)
				r.Route("/knowledge/{agentType}", func(r chi.Router) {
					r.Use(permMW.RequireOrgRole(domain.OrgRoleSMECurator))

					r.Route("/guidelines", func(r chi.Router) {
						r.Post("/", guidelinesHandler.Create)
						r.Get("/", guidelinesHandler.List)
						r.Get("/{id}", guidelinesHandler.Get)
						r.Put("/{id}", guidelinesHandler.Update)
						r.Delete("/{id}", guidelinesHandler.Deactivate)
					})

					r.Route("/templates", func(r chi.Router) {
						r.Post("/", templatesHandler.Create)
						r.Get("/", templatesHandler.List)
						r.Get("/{id}", templatesHandler.Get)
						r.Put("/{id}", templatesHandler.Update)
						r.Delete("/{id}", templatesHandler.Deactivate)
					})

					r.Route("/examples", func(r chi.Router) {
						r.Post("/", examplesHandler.Create)
						r.Get("/", examplesHandler.List)
						r.Get("/{id}", examplesHandler.Get)
						r.Put("/{id}", examplesHandler.Update)
						r.Delete("/{id}", examplesHandler.Deactivate)
					})

					r.Route("/constraints", func(r chi.Router) {
						r.Post("/", constraintsHandler.Create)
						r.Get("/", constraintsHandler.List)
						r.Get("/{id}", constraintsHandler.Get)
						r.Put("/{id}", constraintsHandler.Update)
						r.Delete("/{id}", constraintsHandler.Deactivate)
					})
				})

				// Workflow routes (require project membership)
				r.Route("/workflows", func(r chi.Router) {
					r.Post("/", workflowsHandler.Create)
					r.Get("/{id}", workflowsHandler.Get)
					r.Post("/{id}/advance", workflowsHandler.AdvancePhase)
				})
			})
		})
	})

	return r
}
```

**Step 3: Run build to verify compilation**

Run: `go build ./...`
Expected: No errors

**Step 4: Commit**

```bash
git add internal/api/routes/routes.go
git commit -m "feat(permissions): apply permission middleware to routes"
```

---

## Task 4: Run All Tests

**Step 1: Run all tests**

Run: `go test ./internal/... -v`
Expected: All tests PASS

**Step 2: Run linter**

Run: `go vet ./internal/...`
Expected: No errors

**Step 3: Final commit for part 4**

```bash
git add -A
git commit -m "feat(permissions): complete authorization middleware

- Add AuthService for permission checking
- Implement admin override for project access
- Add RequireOrgMembership middleware
- Add RequireOrgRole middleware
- Add RequireProjectRole middleware with admin bypass
- Apply middleware to all routes
- Add context helpers for user/org ID extraction"
```

---

## Summary

After completing Part 4, you will have:

**Created Files:**
- `internal/service/auth_service.go` - Authorization service
- `internal/service/auth_service_test.go` - Auth service tests
- `internal/api/middleware/permissions.go` - Permission middleware
- `internal/api/middleware/permissions_test.go` - Middleware tests

**Modified Files:**
- `internal/api/routes/routes.go` - Applied middleware to all routes

**Middleware Functions:**
- `RequireAuth` - Validates X-User-ID header
- `RequireOrgMembership` - Checks user is org member
- `RequireOrgRole(role)` - Checks user has required org role
- `RequireProjectRole(role)` - Checks project role with admin override

**Security Features:**
- Admin override for project access
- Cross-org prevention via org membership check
- Role hierarchy enforcement
- Context propagation of user/org info

**Next:** Proceed to [05-sme-knowledge-permissions.md](./05-sme-knowledge-permissions.md)
