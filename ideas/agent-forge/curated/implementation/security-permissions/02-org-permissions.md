# Part 2: Organization Permissions

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement organization management with member CRUD operations and role assignment.

**Architecture:** Repository interface → memory implementation → service layer → HTTP handlers. Follow existing patterns from `internal/repository/knowledge_repository.go` and `internal/service/knowledge_service.go`.

**Tech Stack:** Go, Chi router, following existing codebase patterns

**Prerequisite:** Complete [01-data-models.md](./01-data-models.md) first.

---

## Task 1: Create Repository Interface

**Files:**
- Create: `internal/repository/permissions_repository.go`

**Step 1: Write the failing test**

No test needed - this is an interface definition.

**Step 2: Create the interface**

```go
// internal/repository/permissions_repository.go
package repository

import (
	"context"

	"github.com/anthropics/agentic-platform/internal/domain"
)

// PermissionsRepository defines the interface for permissions storage
type PermissionsRepository interface {
	// Organization methods
	CreateOrganization(ctx context.Context, org *domain.Organization) error
	GetOrganization(ctx context.Context, id string) (*domain.Organization, error)
	UpdateOrganization(ctx context.Context, org *domain.Organization) error

	// Org membership methods
	CreateOrgMembership(ctx context.Context, m *domain.OrgMembership) error
	GetOrgMembership(ctx context.Context, orgID, userID string) (*domain.OrgMembership, error)
	GetOrgMembershipByID(ctx context.Context, id string) (*domain.OrgMembership, error)
	ListOrgMemberships(ctx context.Context, orgID string) ([]*domain.OrgMembership, error)
	ListUserOrgMemberships(ctx context.Context, userID string) ([]*domain.OrgMembership, error)
	UpdateOrgMembership(ctx context.Context, m *domain.OrgMembership) error
	DeleteOrgMembership(ctx context.Context, orgID, userID string) error

	// Project membership methods
	CreateProjectMembership(ctx context.Context, m *domain.ProjectMembership) error
	GetProjectMembership(ctx context.Context, projectID, userID string) (*domain.ProjectMembership, error)
	ListProjectMemberships(ctx context.Context, projectID string) ([]*domain.ProjectMembership, error)
	ListUserProjectMemberships(ctx context.Context, userID string) ([]*domain.ProjectMembership, error)
	UpdateProjectMembership(ctx context.Context, m *domain.ProjectMembership) error
	DeleteProjectMembership(ctx context.Context, projectID, userID string) error
	CountProjectOwners(ctx context.Context, projectID string) (int, error)

	// Marketplace enablement methods
	CreateMarketplaceEnablement(ctx context.Context, m *domain.MarketplaceEnablement) error
	GetMarketplaceEnablement(ctx context.Context, orgID, knowledgeID string) (*domain.MarketplaceEnablement, error)
	ListMarketplaceEnablements(ctx context.Context, orgID string) ([]*domain.MarketplaceEnablement, error)
	DeleteMarketplaceEnablement(ctx context.Context, orgID, knowledgeID string) error
}
```

**Step 3: Commit**

```bash
git add internal/repository/permissions_repository.go
git commit -m "feat(permissions): add PermissionsRepository interface"
```

---

## Task 2: Create Memory Repository - Organization Methods

**Files:**
- Create: `internal/repository/memory/permissions_repository.go`
- Create: `internal/repository/memory/permissions_repository_test.go`

**Step 1: Write the failing test**

```go
// internal/repository/memory/permissions_repository_test.go
package memory

import (
	"context"
	"testing"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

func TestPermissionsRepository_CreateAndGetOrganization(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	org := &domain.Organization{
		ID:        "org-1",
		Name:      "Acme Corp",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Create
	err := repo.CreateOrganization(ctx, org)
	if err != nil {
		t.Fatalf("CreateOrganization() error = %v", err)
	}

	// Create duplicate - should fail
	err = repo.CreateOrganization(ctx, org)
	if err != repository.ErrAlreadyExists {
		t.Errorf("CreateOrganization() duplicate error = %v, want ErrAlreadyExists", err)
	}

	// Get
	got, err := repo.GetOrganization(ctx, "org-1")
	if err != nil {
		t.Fatalf("GetOrganization() error = %v", err)
	}
	if got.Name != org.Name {
		t.Errorf("Name = %v, want %v", got.Name, org.Name)
	}

	// Get non-existent
	_, err = repo.GetOrganization(ctx, "org-999")
	if err != repository.ErrNotFound {
		t.Errorf("GetOrganization() non-existent error = %v, want ErrNotFound", err)
	}
}

func TestPermissionsRepository_UpdateOrganization(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	org := &domain.Organization{
		ID:        "org-1",
		Name:      "Acme Corp",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Create
	_ = repo.CreateOrganization(ctx, org)

	// Update
	org.Name = "Acme Inc"
	org.MandatoryKnowledge = []string{"k-1", "k-2"}
	err := repo.UpdateOrganization(ctx, org)
	if err != nil {
		t.Fatalf("UpdateOrganization() error = %v", err)
	}

	// Verify update
	got, _ := repo.GetOrganization(ctx, "org-1")
	if got.Name != "Acme Inc" {
		t.Errorf("Name = %v, want Acme Inc", got.Name)
	}
	if len(got.MandatoryKnowledge) != 2 {
		t.Errorf("MandatoryKnowledge length = %v, want 2", len(got.MandatoryKnowledge))
	}

	// Update non-existent
	nonExistent := &domain.Organization{ID: "org-999", Name: "Test"}
	err = repo.UpdateOrganization(ctx, nonExistent)
	if err != repository.ErrNotFound {
		t.Errorf("UpdateOrganization() non-existent error = %v, want ErrNotFound", err)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository -v`
Expected: FAIL with "undefined: NewPermissionsRepository"

**Step 3: Write minimal implementation**

```go
// internal/repository/memory/permissions_repository.go
package memory

import (
	"context"
	"sync"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

// PermissionsRepository is an in-memory implementation of repository.PermissionsRepository
type PermissionsRepository struct {
	mu                     sync.RWMutex
	organizations          map[string]*domain.Organization
	orgMemberships         map[string]*domain.OrgMembership         // key: orgID/userID
	projectMemberships     map[string]*domain.ProjectMembership     // key: projectID/userID
	marketplaceEnablements map[string]*domain.MarketplaceEnablement // key: orgID/knowledgeID
}

// NewPermissionsRepository creates a new in-memory permissions repository
func NewPermissionsRepository() *PermissionsRepository {
	return &PermissionsRepository{
		organizations:          make(map[string]*domain.Organization),
		orgMemberships:         make(map[string]*domain.OrgMembership),
		projectMemberships:     make(map[string]*domain.ProjectMembership),
		marketplaceEnablements: make(map[string]*domain.MarketplaceEnablement),
	}
}

// CreateOrganization creates a new organization
func (r *PermissionsRepository) CreateOrganization(ctx context.Context, org *domain.Organization) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.organizations[org.ID]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *org
	if copy.MandatoryKnowledge == nil {
		copy.MandatoryKnowledge = []string{}
	} else {
		copy.MandatoryKnowledge = append([]string{}, org.MandatoryKnowledge...)
	}
	r.organizations[org.ID] = &copy
	return nil
}

// GetOrganization retrieves an organization by ID
func (r *PermissionsRepository) GetOrganization(ctx context.Context, id string) (*domain.Organization, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	org, exists := r.organizations[id]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *org
	copy.MandatoryKnowledge = append([]string{}, org.MandatoryKnowledge...)
	return &copy, nil
}

// UpdateOrganization updates an existing organization
func (r *PermissionsRepository) UpdateOrganization(ctx context.Context, org *domain.Organization) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.organizations[org.ID]; !exists {
		return repository.ErrNotFound
	}

	copy := *org
	if copy.MandatoryKnowledge == nil {
		copy.MandatoryKnowledge = []string{}
	} else {
		copy.MandatoryKnowledge = append([]string{}, org.MandatoryKnowledge...)
	}
	r.organizations[org.ID] = &copy
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/permissions_repository.go internal/repository/memory/permissions_repository_test.go
git commit -m "feat(permissions): add memory repository for organizations"
```

---

## Task 3: Add Org Membership Repository Methods

**Files:**
- Modify: `internal/repository/memory/permissions_repository.go`
- Modify: `internal/repository/memory/permissions_repository_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/repository/memory/permissions_repository_test.go
func TestPermissionsRepository_OrgMembership(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	m := &domain.OrgMembership{
		ID:       "m-1",
		OrgID:    "org-1",
		UserID:   "user-1",
		Role:     domain.OrgRoleMember,
		JoinedAt: time.Now(),
	}

	// Create
	err := repo.CreateOrgMembership(ctx, m)
	if err != nil {
		t.Fatalf("CreateOrgMembership() error = %v", err)
	}

	// Create duplicate - should fail
	err = repo.CreateOrgMembership(ctx, m)
	if err != repository.ErrAlreadyExists {
		t.Errorf("CreateOrgMembership() duplicate error = %v, want ErrAlreadyExists", err)
	}

	// Get by org and user
	got, err := repo.GetOrgMembership(ctx, "org-1", "user-1")
	if err != nil {
		t.Fatalf("GetOrgMembership() error = %v", err)
	}
	if got.Role != domain.OrgRoleMember {
		t.Errorf("Role = %v, want %v", got.Role, domain.OrgRoleMember)
	}

	// Get by ID
	gotByID, err := repo.GetOrgMembershipByID(ctx, "m-1")
	if err != nil {
		t.Fatalf("GetOrgMembershipByID() error = %v", err)
	}
	if gotByID.UserID != "user-1" {
		t.Errorf("UserID = %v, want user-1", gotByID.UserID)
	}

	// Get non-existent
	_, err = repo.GetOrgMembership(ctx, "org-1", "user-999")
	if err != repository.ErrNotFound {
		t.Errorf("GetOrgMembership() non-existent error = %v, want ErrNotFound", err)
	}
}

func TestPermissionsRepository_ListOrgMemberships(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	// Create memberships in different orgs
	memberships := []*domain.OrgMembership{
		{ID: "m-1", OrgID: "org-1", UserID: "user-1", Role: domain.OrgRoleAdmin},
		{ID: "m-2", OrgID: "org-1", UserID: "user-2", Role: domain.OrgRoleMember},
		{ID: "m-3", OrgID: "org-2", UserID: "user-1", Role: domain.OrgRoleMember},
	}

	for _, m := range memberships {
		_ = repo.CreateOrgMembership(ctx, m)
	}

	// List by org
	org1Members, err := repo.ListOrgMemberships(ctx, "org-1")
	if err != nil {
		t.Fatalf("ListOrgMemberships() error = %v", err)
	}
	if len(org1Members) != 2 {
		t.Errorf("ListOrgMemberships() count = %v, want 2", len(org1Members))
	}

	// List by user
	user1Orgs, err := repo.ListUserOrgMemberships(ctx, "user-1")
	if err != nil {
		t.Fatalf("ListUserOrgMemberships() error = %v", err)
	}
	if len(user1Orgs) != 2 {
		t.Errorf("ListUserOrgMemberships() count = %v, want 2", len(user1Orgs))
	}
}

func TestPermissionsRepository_UpdateAndDeleteOrgMembership(t *testing.T) {
	repo := NewPermissionsRepository()
	ctx := context.Background()

	m := &domain.OrgMembership{
		ID:     "m-1",
		OrgID:  "org-1",
		UserID: "user-1",
		Role:   domain.OrgRoleMember,
	}
	_ = repo.CreateOrgMembership(ctx, m)

	// Update role
	m.Role = domain.OrgRoleAdmin
	err := repo.UpdateOrgMembership(ctx, m)
	if err != nil {
		t.Fatalf("UpdateOrgMembership() error = %v", err)
	}

	got, _ := repo.GetOrgMembership(ctx, "org-1", "user-1")
	if got.Role != domain.OrgRoleAdmin {
		t.Errorf("Role = %v, want admin", got.Role)
	}

	// Delete
	err = repo.DeleteOrgMembership(ctx, "org-1", "user-1")
	if err != nil {
		t.Fatalf("DeleteOrgMembership() error = %v", err)
	}

	// Verify deleted
	_, err = repo.GetOrgMembership(ctx, "org-1", "user-1")
	if err != repository.ErrNotFound {
		t.Errorf("GetOrgMembership() after delete error = %v, want ErrNotFound", err)
	}

	// Delete non-existent
	err = repo.DeleteOrgMembership(ctx, "org-1", "user-999")
	if err != repository.ErrNotFound {
		t.Errorf("DeleteOrgMembership() non-existent error = %v, want ErrNotFound", err)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/repository/memory/... -run TestPermissionsRepository_OrgMembership -v`
Expected: FAIL with method not defined

**Step 3: Write minimal implementation**

```go
// Add to internal/repository/memory/permissions_repository.go

func (r *PermissionsRepository) orgMembershipKey(orgID, userID string) string {
	return orgID + "/" + userID
}

// CreateOrgMembership creates a new org membership
func (r *PermissionsRepository) CreateOrgMembership(ctx context.Context, m *domain.OrgMembership) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.orgMembershipKey(m.OrgID, m.UserID)
	if _, exists := r.orgMemberships[key]; exists {
		return repository.ErrAlreadyExists
	}

	copy := *m
	r.orgMemberships[key] = &copy
	return nil
}

// GetOrgMembership retrieves an org membership by org and user ID
func (r *PermissionsRepository) GetOrgMembership(ctx context.Context, orgID, userID string) (*domain.OrgMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := r.orgMembershipKey(orgID, userID)
	m, exists := r.orgMemberships[key]
	if !exists {
		return nil, repository.ErrNotFound
	}

	copy := *m
	return &copy, nil
}

// GetOrgMembershipByID retrieves an org membership by its ID
func (r *PermissionsRepository) GetOrgMembershipByID(ctx context.Context, id string) (*domain.OrgMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, m := range r.orgMemberships {
		if m.ID == id {
			copy := *m
			return &copy, nil
		}
	}
	return nil, repository.ErrNotFound
}

// ListOrgMemberships returns all memberships for an organization
func (r *PermissionsRepository) ListOrgMemberships(ctx context.Context, orgID string) ([]*domain.OrgMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.OrgMembership
	for _, m := range r.orgMemberships {
		if m.OrgID == orgID {
			copy := *m
			result = append(result, &copy)
		}
	}
	return result, nil
}

// ListUserOrgMemberships returns all org memberships for a user
func (r *PermissionsRepository) ListUserOrgMemberships(ctx context.Context, userID string) ([]*domain.OrgMembership, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.OrgMembership
	for _, m := range r.orgMemberships {
		if m.UserID == userID {
			copy := *m
			result = append(result, &copy)
		}
	}
	return result, nil
}

// UpdateOrgMembership updates an existing org membership
func (r *PermissionsRepository) UpdateOrgMembership(ctx context.Context, m *domain.OrgMembership) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.orgMembershipKey(m.OrgID, m.UserID)
	if _, exists := r.orgMemberships[key]; !exists {
		return repository.ErrNotFound
	}

	copy := *m
	r.orgMemberships[key] = &copy
	return nil
}

// DeleteOrgMembership removes an org membership
func (r *PermissionsRepository) DeleteOrgMembership(ctx context.Context, orgID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := r.orgMembershipKey(orgID, userID)
	if _, exists := r.orgMemberships[key]; !exists {
		return repository.ErrNotFound
	}

	delete(r.orgMemberships, key)
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/repository/memory/... -run "TestPermissionsRepository_(OrgMembership|List|Update)" -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/repository/memory/permissions_repository.go internal/repository/memory/permissions_repository_test.go
git commit -m "feat(permissions): add org membership repository methods"
```

---

## Task 4: Create Organization Service

**Files:**
- Create: `internal/service/org_service.go`
- Create: `internal/service/org_service_test.go`

**Step 1: Write the failing test**

```go
// internal/service/org_service_test.go
package service

import (
	"context"
	"testing"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository/memory"
)

func TestOrgService_CreateOrganization(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	input := CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "user-1",
	}

	org, err := svc.CreateOrganization(ctx, input)
	if err != nil {
		t.Fatalf("CreateOrganization() error = %v", err)
	}

	if org.ID == "" {
		t.Error("ID should be generated")
	}
	if org.Name != "Acme Corp" {
		t.Errorf("Name = %v, want Acme Corp", org.Name)
	}

	// Verify creator was added as admin
	membership, err := repo.GetOrgMembership(ctx, org.ID, "user-1")
	if err != nil {
		t.Fatalf("Creator membership not found: %v", err)
	}
	if membership.Role != domain.OrgRoleAdmin {
		t.Errorf("Creator role = %v, want admin", membership.Role)
	}
}

func TestOrgService_AddMember(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	// Create org first
	org, _ := svc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	// Add member
	input := AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "user-2",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	}

	membership, err := svc.AddMember(ctx, input)
	if err != nil {
		t.Fatalf("AddMember() error = %v", err)
	}

	if membership.Role != domain.OrgRoleMember {
		t.Errorf("Role = %v, want member", membership.Role)
	}

	// Add duplicate - should fail
	_, err = svc.AddMember(ctx, input)
	if err == nil {
		t.Error("AddMember() duplicate should fail")
	}
}

func TestOrgService_UpdateMemberRole(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	// Create org and add member
	org, _ := svc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})
	_, _ = svc.AddMember(ctx, AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "user-2",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	})

	// Update role
	input := UpdateOrgMemberInput{
		OrgID:  org.ID,
		UserID: "user-2",
		Role:   domain.OrgRoleProjectLead,
	}

	membership, err := svc.UpdateMemberRole(ctx, input)
	if err != nil {
		t.Fatalf("UpdateMemberRole() error = %v", err)
	}

	if membership.Role != domain.OrgRoleProjectLead {
		t.Errorf("Role = %v, want project_lead", membership.Role)
	}
}

func TestOrgService_RemoveMember(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := NewOrgService(repo)
	ctx := context.Background()

	// Create org and add member
	org, _ := svc.CreateOrganization(ctx, CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})
	_, _ = svc.AddMember(ctx, AddOrgMemberInput{
		OrgID:     org.ID,
		UserID:    "user-2",
		Role:      domain.OrgRoleMember,
		InvitedBy: "admin-1",
	})

	// Remove member
	err := svc.RemoveMember(ctx, org.ID, "user-2")
	if err != nil {
		t.Fatalf("RemoveMember() error = %v", err)
	}

	// Verify removed
	_, err = repo.GetOrgMembership(ctx, org.ID, "user-2")
	if err == nil {
		t.Error("Member should be removed")
	}

	// Remove last admin - should fail
	err = svc.RemoveMember(ctx, org.ID, "admin-1")
	if err == nil {
		t.Error("RemoveMember() should fail when removing last admin")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/service/... -run TestOrgService -v`
Expected: FAIL with "undefined: NewOrgService"

**Step 3: Write minimal implementation**

```go
// internal/service/org_service.go
package service

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
)

var (
	ErrLastAdmin = errors.New("cannot remove the last admin")
)

// OrgService handles organization business logic
type OrgService struct {
	repo repository.PermissionsRepository
}

// NewOrgService creates a new organization service
func NewOrgService(repo repository.PermissionsRepository) *OrgService {
	return &OrgService{repo: repo}
}

// CreateOrgInput contains fields for creating an organization
type CreateOrgInput struct {
	Name      string
	CreatedBy string
}

// AddOrgMemberInput contains fields for adding an org member
type AddOrgMemberInput struct {
	OrgID     string
	UserID    string
	Role      domain.OrgRole
	InvitedBy string
}

// UpdateOrgMemberInput contains fields for updating a member's role
type UpdateOrgMemberInput struct {
	OrgID  string
	UserID string
	Role   domain.OrgRole
}

// CreateOrganization creates a new organization and adds the creator as admin
func (s *OrgService) CreateOrganization(ctx context.Context, input CreateOrgInput) (*domain.Organization, error) {
	now := time.Now()

	org := &domain.Organization{
		ID:                 generateOrgID(),
		Name:               input.Name,
		MandatoryKnowledge: []string{},
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	if err := org.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateOrganization(ctx, org); err != nil {
		return nil, err
	}

	// Add creator as admin
	membership := &domain.OrgMembership{
		ID:        generateMembershipID(),
		OrgID:     org.ID,
		UserID:    input.CreatedBy,
		Role:      domain.OrgRoleAdmin,
		InvitedBy: input.CreatedBy,
		JoinedAt:  now,
	}

	if err := s.repo.CreateOrgMembership(ctx, membership); err != nil {
		return nil, err
	}

	return org, nil
}

// GetOrganization retrieves an organization by ID
func (s *OrgService) GetOrganization(ctx context.Context, id string) (*domain.Organization, error) {
	return s.repo.GetOrganization(ctx, id)
}

// AddMember adds a new member to an organization
func (s *OrgService) AddMember(ctx context.Context, input AddOrgMemberInput) (*domain.OrgMembership, error) {
	if !input.Role.IsValid() {
		return nil, errors.New("invalid role")
	}

	membership := &domain.OrgMembership{
		ID:        generateMembershipID(),
		OrgID:     input.OrgID,
		UserID:    input.UserID,
		Role:      input.Role,
		InvitedBy: input.InvitedBy,
		JoinedAt:  time.Now(),
	}

	if err := membership.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.CreateOrgMembership(ctx, membership); err != nil {
		return nil, err
	}

	return membership, nil
}

// UpdateMemberRole updates a member's role in an organization
func (s *OrgService) UpdateMemberRole(ctx context.Context, input UpdateOrgMemberInput) (*domain.OrgMembership, error) {
	if !input.Role.IsValid() {
		return nil, errors.New("invalid role")
	}

	membership, err := s.repo.GetOrgMembership(ctx, input.OrgID, input.UserID)
	if err != nil {
		return nil, err
	}

	membership.Role = input.Role

	if err := s.repo.UpdateOrgMembership(ctx, membership); err != nil {
		return nil, err
	}

	return membership, nil
}

// RemoveMember removes a member from an organization
func (s *OrgService) RemoveMember(ctx context.Context, orgID, userID string) error {
	// Check if this is the last admin
	membership, err := s.repo.GetOrgMembership(ctx, orgID, userID)
	if err != nil {
		return err
	}

	if membership.Role == domain.OrgRoleAdmin {
		// Count admins
		members, err := s.repo.ListOrgMemberships(ctx, orgID)
		if err != nil {
			return err
		}

		adminCount := 0
		for _, m := range members {
			if m.Role == domain.OrgRoleAdmin {
				adminCount++
			}
		}

		if adminCount <= 1 {
			return ErrLastAdmin
		}
	}

	return s.repo.DeleteOrgMembership(ctx, orgID, userID)
}

// ListMembers returns all members of an organization
func (s *OrgService) ListMembers(ctx context.Context, orgID string) ([]*domain.OrgMembership, error) {
	return s.repo.ListOrgMemberships(ctx, orgID)
}

// GetMember retrieves a specific member's info
func (s *OrgService) GetMember(ctx context.Context, orgID, userID string) (*domain.OrgMembership, error) {
	return s.repo.GetOrgMembership(ctx, orgID, userID)
}

func generateOrgID() string {
	return fmt.Sprintf("org-%d-%s", time.Now().UnixNano()/1000000%1000000000, randomString(6))
}

func generateMembershipID() string {
	return fmt.Sprintf("mem-%d-%s", time.Now().UnixNano()/1000000%1000000000, randomString(6))
}

func randomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/service/... -run TestOrgService -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/service/org_service.go internal/service/org_service_test.go
git commit -m "feat(permissions): add organization service with member management"
```

---

## Task 5: Create Organizations HTTP Handler

**Files:**
- Create: `internal/api/handlers/organizations.go`
- Create: `internal/api/handlers/organizations_test.go`

**Step 1: Write the failing test**

```go
// internal/api/handlers/organizations_test.go
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

func TestOrganizationsHandler_Create(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewOrgService(repo)
	handler := NewOrganizationsHandler(svc)

	reqBody := CreateOrganizationRequest{Name: "Acme Corp"}
	body, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/orgs", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "user-1")

	w := httptest.NewRecorder()
	handler.Create(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusCreated)
	}

	var resp domain.Organization
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.Name != "Acme Corp" {
		t.Errorf("Name = %s, want Acme Corp", resp.Name)
	}
}

func TestOrganizationsHandler_Get(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewOrgService(repo)
	handler := NewOrganizationsHandler(svc)

	// Create org first
	org, _ := svc.CreateOrganization(context.Background(), service.CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "user-1",
	})

	// Create request with chi context
	req := httptest.NewRequest(http.MethodGet, "/api/v1/orgs/"+org.ID, nil)
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", org.ID)
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.Get(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusOK)
	}

	var resp domain.Organization
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.Name != "Acme Corp" {
		t.Errorf("Name = %s, want Acme Corp", resp.Name)
	}
}

func TestOrganizationsHandler_AddMember(t *testing.T) {
	repo := memory.NewPermissionsRepository()
	svc := service.NewOrgService(repo)
	handler := NewOrganizationsHandler(svc)

	// Create org first
	org, _ := svc.CreateOrganization(context.Background(), service.CreateOrgInput{
		Name:      "Acme Corp",
		CreatedBy: "admin-1",
	})

	reqBody := AddMemberRequest{
		UserID: "user-2",
		Role:   domain.OrgRoleMember,
	}
	body, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/orgs/"+org.ID+"/members", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-ID", "admin-1")
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("orgID", org.ID)
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	w := httptest.NewRecorder()
	handler.AddMember(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("Status = %d, want %d", w.Code, http.StatusCreated)
	}

	var resp domain.OrgMembership
	_ = json.NewDecoder(w.Body).Decode(&resp)

	if resp.Role != domain.OrgRoleMember {
		t.Errorf("Role = %s, want member", resp.Role)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/api/handlers/... -run TestOrganizationsHandler -v`
Expected: FAIL with "undefined: NewOrganizationsHandler"

**Step 3: Write minimal implementation**

```go
// internal/api/handlers/organizations.go
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/anthropics/agentic-platform/internal/domain"
	"github.com/anthropics/agentic-platform/internal/repository"
	"github.com/anthropics/agentic-platform/internal/service"
)

// OrganizationsHandler handles organization HTTP requests
type OrganizationsHandler struct {
	svc *service.OrgService
}

// NewOrganizationsHandler creates a new organizations handler
func NewOrganizationsHandler(svc *service.OrgService) *OrganizationsHandler {
	return &OrganizationsHandler{svc: svc}
}

// CreateOrganizationRequest is the request body for creating an organization
type CreateOrganizationRequest struct {
	Name string `json:"name"`
}

// AddMemberRequest is the request body for adding a member
type AddMemberRequest struct {
	UserID string         `json:"userId"`
	Role   domain.OrgRole `json:"role"`
}

// UpdateMemberRequest is the request body for updating a member's role
type UpdateMemberRequest struct {
	Role domain.OrgRole `json:"role"`
}

// Create handles POST /api/v1/orgs
func (h *OrganizationsHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		userID = "system"
	}

	var req CreateOrganizationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.CreateOrgInput{
		Name:      req.Name,
		CreatedBy: userID,
	}

	org, err := h.svc.CreateOrganization(r.Context(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(org)
}

// Get handles GET /api/v1/orgs/{orgID}
func (h *OrganizationsHandler) Get(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")

	org, err := h.svc.GetOrganization(r.Context(), orgID)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "organization not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(org)
}

// ListMembers handles GET /api/v1/orgs/{orgID}/members
func (h *OrganizationsHandler) ListMembers(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")

	members, err := h.svc.ListMembers(r.Context(), orgID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(members)
}

// AddMember handles POST /api/v1/orgs/{orgID}/members
func (h *OrganizationsHandler) AddMember(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	invitedBy := r.Header.Get("X-User-ID")
	if invitedBy == "" {
		invitedBy = "system"
	}

	var req AddMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.AddOrgMemberInput{
		OrgID:     orgID,
		UserID:    req.UserID,
		Role:      req.Role,
		InvitedBy: invitedBy,
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

// GetMember handles GET /api/v1/orgs/{orgID}/members/{userID}
func (h *OrganizationsHandler) GetMember(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	userID := chi.URLParam(r, "userID")

	membership, err := h.svc.GetMember(r.Context(), orgID, userID)
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

// UpdateMember handles PUT /api/v1/orgs/{orgID}/members/{userID}
func (h *OrganizationsHandler) UpdateMember(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	userID := chi.URLParam(r, "userID")

	var req UpdateMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	input := service.UpdateOrgMemberInput{
		OrgID:  orgID,
		UserID: userID,
		Role:   req.Role,
	}

	membership, err := h.svc.UpdateMemberRole(r.Context(), input)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "member not found", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(membership)
}

// RemoveMember handles DELETE /api/v1/orgs/{orgID}/members/{userID}
func (h *OrganizationsHandler) RemoveMember(w http.ResponseWriter, r *http.Request) {
	orgID := chi.URLParam(r, "orgID")
	userID := chi.URLParam(r, "userID")

	err := h.svc.RemoveMember(r.Context(), orgID, userID)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "member not found", http.StatusNotFound)
			return
		}
		if err == service.ErrLastAdmin {
			http.Error(w, "cannot remove the last admin", http.StatusBadRequest)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/api/handlers/... -run TestOrganizationsHandler -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/api/handlers/organizations.go internal/api/handlers/organizations_test.go
git commit -m "feat(permissions): add organizations HTTP handler"
```

---

## Task 6: Register Organization Routes

**Files:**
- Modify: `internal/api/routes/routes.go`

**Step 1: Read current routes file**

Read the file to understand current structure.

**Step 2: Update routes to include organization endpoints**

Add to the routes setup function:

```go
// Add to imports
import (
	// ... existing imports
	"github.com/anthropics/agentic-platform/internal/api/handlers"
	"github.com/anthropics/agentic-platform/internal/service"
)

// In Setup function, add:
func Setup(
	knowledgeRepo repository.KnowledgeRepository,
	workflowRepo repository.WorkflowRepository,
	permissionsRepo repository.PermissionsRepository,  // Add this parameter
) *chi.Mux {
	// ... existing code

	// Organization service and handler
	orgSvc := service.NewOrgService(permissionsRepo)
	orgsHandler := handlers.NewOrganizationsHandler(orgSvc)

	r.Route("/api/v1", func(r chi.Router) {
		// Organization routes
		r.Route("/orgs", func(r chi.Router) {
			r.Post("/", orgsHandler.Create)

			r.Route("/{orgID}", func(r chi.Router) {
				r.Get("/", orgsHandler.Get)

				r.Route("/members", func(r chi.Router) {
					r.Get("/", orgsHandler.ListMembers)
					r.Post("/", orgsHandler.AddMember)
					r.Get("/{userID}", orgsHandler.GetMember)
					r.Put("/{userID}", orgsHandler.UpdateMember)
					r.Delete("/{userID}", orgsHandler.RemoveMember)
				})

				// ... existing org routes (knowledge, etc.)
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
git commit -m "feat(permissions): register organization routes"
```

---

## Task 7: Run All Organization Tests

**Step 1: Run all tests**

Run: `go test ./internal/... -v`
Expected: All tests PASS

**Step 2: Run linter**

Run: `go vet ./internal/...`
Expected: No errors

**Step 3: Final commit for part 2**

```bash
git add -A
git commit -m "feat(permissions): complete organization permissions implementation

- Add PermissionsRepository interface
- Implement memory repository for orgs and memberships
- Add OrgService with member management
- Add HTTP handlers for organization CRUD
- Register organization routes
- Prevent removal of last admin"
```

---

## Summary

After completing Part 2, you will have:

**Created Files:**
- `internal/repository/permissions_repository.go` - Repository interface
- `internal/repository/memory/permissions_repository.go` - Memory implementation
- `internal/repository/memory/permissions_repository_test.go` - Repository tests
- `internal/service/org_service.go` - Organization service
- `internal/service/org_service_test.go` - Service tests
- `internal/api/handlers/organizations.go` - HTTP handlers
- `internal/api/handlers/organizations_test.go` - Handler tests

**Modified Files:**
- `internal/api/routes/routes.go` - Added organization routes

**API Endpoints:**
- `POST /api/v1/orgs` - Create organization
- `GET /api/v1/orgs/{orgID}` - Get organization
- `GET /api/v1/orgs/{orgID}/members` - List members
- `POST /api/v1/orgs/{orgID}/members` - Add member
- `GET /api/v1/orgs/{orgID}/members/{userID}` - Get member
- `PUT /api/v1/orgs/{orgID}/members/{userID}` - Update member role
- `DELETE /api/v1/orgs/{orgID}/members/{userID}` - Remove member

**Next:** Proceed to [03-project-permissions.md](./03-project-permissions.md)
