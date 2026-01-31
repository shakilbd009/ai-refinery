# Part 1: Permission Data Models

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create domain models for organizations, memberships, and role enums with validation.

**Architecture:** Follow existing domain model patterns in `internal/domain/` - Firestore/JSON struct tags, enum types with `IsValid()` methods, `Validate()` methods on models.

**Tech Stack:** Go, following patterns from `internal/domain/knowledge.go` and `internal/domain/workflow.go`

---

## Task 1: Create OrgRole Enum

**Files:**
- Create: `internal/domain/permissions.go`
- Test: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// internal/domain/permissions_test.go
package domain

import "testing"

func TestOrgRole_IsValid(t *testing.T) {
	tests := []struct {
		role  OrgRole
		valid bool
	}{
		{OrgRoleAdmin, true},
		{OrgRoleSMECurator, true},
		{OrgRoleProjectLead, true},
		{OrgRoleMember, true},
		{OrgRole("invalid"), false},
		{OrgRole(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.role), func(t *testing.T) {
			if got := tt.role.IsValid(); got != tt.valid {
				t.Errorf("OrgRole(%q).IsValid() = %v, want %v", tt.role, got, tt.valid)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestOrgRole_IsValid -v`
Expected: FAIL with "undefined: OrgRole"

**Step 3: Write minimal implementation**

```go
// internal/domain/permissions.go
package domain

// OrgRole represents a user's role within an organization
type OrgRole string

const (
	OrgRoleAdmin       OrgRole = "admin"
	OrgRoleSMECurator  OrgRole = "sme_curator"
	OrgRoleProjectLead OrgRole = "project_lead"
	OrgRoleMember      OrgRole = "member"
)

// IsValid checks if the role is a valid org role
func (r OrgRole) IsValid() bool {
	switch r {
	case OrgRoleAdmin, OrgRoleSMECurator, OrgRoleProjectLead, OrgRoleMember:
		return true
	}
	return false
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestOrgRole_IsValid -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add OrgRole enum with validation"
```

---

## Task 2: Create ProjectRole Enum

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestProjectRole_IsValid(t *testing.T) {
	tests := []struct {
		role  ProjectRole
		valid bool
	}{
		{ProjectRoleOwner, true},
		{ProjectRoleEditor, true},
		{ProjectRoleApprover, true},
		{ProjectRoleViewer, true},
		{ProjectRole("invalid"), false},
		{ProjectRole(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.role), func(t *testing.T) {
			if got := tt.role.IsValid(); got != tt.valid {
				t.Errorf("ProjectRole(%q).IsValid() = %v, want %v", tt.role, got, tt.valid)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestProjectRole_IsValid -v`
Expected: FAIL with "undefined: ProjectRole"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go

// ProjectRole represents a user's role within a project
type ProjectRole string

const (
	ProjectRoleOwner    ProjectRole = "owner"
	ProjectRoleEditor   ProjectRole = "editor"
	ProjectRoleApprover ProjectRole = "approver"
	ProjectRoleViewer   ProjectRole = "viewer"
)

// IsValid checks if the role is a valid project role
func (r ProjectRole) IsValid() bool {
	switch r {
	case ProjectRoleOwner, ProjectRoleEditor, ProjectRoleApprover, ProjectRoleViewer:
		return true
	}
	return false
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestProjectRole_IsValid -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add ProjectRole enum with validation"
```

---

## Task 3: Add Role Hierarchy Methods

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestProjectRole_CanActAs(t *testing.T) {
	tests := []struct {
		role   ProjectRole
		target ProjectRole
		can    bool
	}{
		// Owner can act as any role
		{ProjectRoleOwner, ProjectRoleOwner, true},
		{ProjectRoleOwner, ProjectRoleEditor, true},
		{ProjectRoleOwner, ProjectRoleApprover, true},
		{ProjectRoleOwner, ProjectRoleViewer, true},
		// Editor can act as Approver and Viewer
		{ProjectRoleEditor, ProjectRoleOwner, false},
		{ProjectRoleEditor, ProjectRoleEditor, true},
		{ProjectRoleEditor, ProjectRoleApprover, true},
		{ProjectRoleEditor, ProjectRoleViewer, true},
		// Approver can act as Viewer
		{ProjectRoleApprover, ProjectRoleOwner, false},
		{ProjectRoleApprover, ProjectRoleEditor, false},
		{ProjectRoleApprover, ProjectRoleApprover, true},
		{ProjectRoleApprover, ProjectRoleViewer, true},
		// Viewer can only act as Viewer
		{ProjectRoleViewer, ProjectRoleOwner, false},
		{ProjectRoleViewer, ProjectRoleEditor, false},
		{ProjectRoleViewer, ProjectRoleApprover, false},
		{ProjectRoleViewer, ProjectRoleViewer, true},
	}

	for _, tt := range tests {
		name := string(tt.role) + "_as_" + string(tt.target)
		t.Run(name, func(t *testing.T) {
			if got := tt.role.CanActAs(tt.target); got != tt.can {
				t.Errorf("%s.CanActAs(%s) = %v, want %v", tt.role, tt.target, got, tt.can)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestProjectRole_CanActAs -v`
Expected: FAIL with "tt.role.CanActAs undefined"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go

// projectRoleLevel returns the hierarchy level (higher = more permissions)
func (r ProjectRole) level() int {
	switch r {
	case ProjectRoleOwner:
		return 4
	case ProjectRoleEditor:
		return 3
	case ProjectRoleApprover:
		return 2
	case ProjectRoleViewer:
		return 1
	}
	return 0
}

// CanActAs returns true if this role has at least the permissions of the target role
func (r ProjectRole) CanActAs(target ProjectRole) bool {
	return r.level() >= target.level()
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestProjectRole_CanActAs -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add ProjectRole hierarchy with CanActAs method"
```

---

## Task 4: Create Organization Model

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestOrganization_Validate(t *testing.T) {
	tests := []struct {
		name    string
		org     Organization
		wantErr bool
	}{
		{
			name: "valid organization",
			org: Organization{
				ID:   "org-1",
				Name: "Acme Corp",
			},
			wantErr: false,
		},
		{
			name: "missing id",
			org: Organization{
				Name: "Acme Corp",
			},
			wantErr: true,
		},
		{
			name: "missing name",
			org: Organization{
				ID: "org-1",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.org.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Organization.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestOrganization_Validate -v`
Expected: FAIL with "undefined: Organization"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go
import (
	"errors"
	"time"
)

// Organization represents a tenant in the multi-tenant system
type Organization struct {
	ID                 string    `json:"id" firestore:"id"`
	Name               string    `json:"name" firestore:"name"`
	MandatoryKnowledge []string  `json:"mandatoryKnowledge" firestore:"mandatoryKnowledge"`
	CreatedAt          time.Time `json:"createdAt" firestore:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt" firestore:"updatedAt"`
}

// Validate checks if the organization has all required fields
func (o *Organization) Validate() error {
	if o.ID == "" {
		return errors.New("id is required")
	}
	if o.Name == "" {
		return errors.New("name is required")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestOrganization_Validate -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add Organization model with validation"
```

---

## Task 5: Create OrgMembership Model

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestOrgMembership_Validate(t *testing.T) {
	tests := []struct {
		name    string
		m       OrgMembership
		wantErr bool
	}{
		{
			name: "valid membership",
			m: OrgMembership{
				ID:     "mem-1",
				OrgID:  "org-1",
				UserID: "user-1",
				Role:   OrgRoleMember,
			},
			wantErr: false,
		},
		{
			name: "missing org id",
			m: OrgMembership{
				ID:     "mem-1",
				UserID: "user-1",
				Role:   OrgRoleMember,
			},
			wantErr: true,
		},
		{
			name: "missing user id",
			m: OrgMembership{
				ID:    "mem-1",
				OrgID: "org-1",
				Role:  OrgRoleMember,
			},
			wantErr: true,
		},
		{
			name: "invalid role",
			m: OrgMembership{
				ID:     "mem-1",
				OrgID:  "org-1",
				UserID: "user-1",
				Role:   OrgRole("invalid"),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.m.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("OrgMembership.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestOrgMembership_Validate -v`
Expected: FAIL with "undefined: OrgMembership"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go

// OrgMembership represents a user's membership in an organization
type OrgMembership struct {
	ID        string    `json:"id" firestore:"id"`
	OrgID     string    `json:"orgId" firestore:"orgId"`
	UserID    string    `json:"userId" firestore:"userId"`
	Role      OrgRole   `json:"role" firestore:"role"`
	InvitedBy string    `json:"invitedBy" firestore:"invitedBy"`
	JoinedAt  time.Time `json:"joinedAt" firestore:"joinedAt"`
}

// Validate checks if the membership has all required fields
func (m *OrgMembership) Validate() error {
	if m.OrgID == "" {
		return errors.New("orgId is required")
	}
	if m.UserID == "" {
		return errors.New("userId is required")
	}
	if !m.Role.IsValid() {
		return errors.New("invalid role")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestOrgMembership_Validate -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add OrgMembership model with validation"
```

---

## Task 6: Create ProjectMembership Model

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestProjectMembership_Validate(t *testing.T) {
	tests := []struct {
		name    string
		m       ProjectMembership
		wantErr bool
	}{
		{
			name: "valid membership",
			m: ProjectMembership{
				ID:        "pm-1",
				ProjectID: "proj-1",
				UserID:    "user-1",
				Role:      ProjectRoleEditor,
			},
			wantErr: false,
		},
		{
			name: "missing project id",
			m: ProjectMembership{
				ID:     "pm-1",
				UserID: "user-1",
				Role:   ProjectRoleEditor,
			},
			wantErr: true,
		},
		{
			name: "missing user id",
			m: ProjectMembership{
				ID:        "pm-1",
				ProjectID: "proj-1",
				Role:      ProjectRoleEditor,
			},
			wantErr: true,
		},
		{
			name: "invalid role",
			m: ProjectMembership{
				ID:        "pm-1",
				ProjectID: "proj-1",
				UserID:    "user-1",
				Role:      ProjectRole("invalid"),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.m.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("ProjectMembership.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestProjectMembership_Validate -v`
Expected: FAIL with "undefined: ProjectMembership"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go

// ProjectMembership represents a user's membership in a project
type ProjectMembership struct {
	ID        string      `json:"id" firestore:"id"`
	ProjectID string      `json:"projectId" firestore:"projectId"`
	UserID    string      `json:"userId" firestore:"userId"`
	Role      ProjectRole `json:"role" firestore:"role"`
	AddedBy   string      `json:"addedBy" firestore:"addedBy"`
	AddedAt   time.Time   `json:"addedAt" firestore:"addedAt"`
}

// Validate checks if the membership has all required fields
func (m *ProjectMembership) Validate() error {
	if m.ProjectID == "" {
		return errors.New("projectId is required")
	}
	if m.UserID == "" {
		return errors.New("userId is required")
	}
	if !m.Role.IsValid() {
		return errors.New("invalid role")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestProjectMembership_Validate -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add ProjectMembership model with validation"
```

---

## Task 7: Create MarketplaceEnablement Model

**Files:**
- Modify: `internal/domain/permissions.go`
- Modify: `internal/domain/permissions_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/permissions_test.go
func TestMarketplaceEnablement_Validate(t *testing.T) {
	tests := []struct {
		name    string
		m       MarketplaceEnablement
		wantErr bool
	}{
		{
			name: "valid enablement",
			m: MarketplaceEnablement{
				ID:          "me-1",
				OrgID:       "org-1",
				KnowledgeID: "k-1",
			},
			wantErr: false,
		},
		{
			name: "missing org id",
			m: MarketplaceEnablement{
				ID:          "me-1",
				KnowledgeID: "k-1",
			},
			wantErr: true,
		},
		{
			name: "missing knowledge id",
			m: MarketplaceEnablement{
				ID:    "me-1",
				OrgID: "org-1",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.m.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("MarketplaceEnablement.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestMarketplaceEnablement_Validate -v`
Expected: FAIL with "undefined: MarketplaceEnablement"

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/permissions.go

// MarketplaceEnablement tracks which marketplace items an org has enabled
type MarketplaceEnablement struct {
	ID          string    `json:"id" firestore:"id"`
	OrgID       string    `json:"orgId" firestore:"orgId"`
	KnowledgeID string    `json:"knowledgeId" firestore:"knowledgeId"`
	EnabledBy   string    `json:"enabledBy" firestore:"enabledBy"`
	EnabledAt   time.Time `json:"enabledAt" firestore:"enabledAt"`
}

// Validate checks if the enablement has all required fields
func (m *MarketplaceEnablement) Validate() error {
	if m.OrgID == "" {
		return errors.New("orgId is required")
	}
	if m.KnowledgeID == "" {
		return errors.New("knowledgeId is required")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestMarketplaceEnablement_Validate -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/permissions.go internal/domain/permissions_test.go
git commit -m "feat(permissions): add MarketplaceEnablement model with validation"
```

---

## Task 8: Run All Tests and Final Commit

**Step 1: Run all domain tests**

Run: `go test ./internal/domain/... -v`
Expected: All tests PASS

**Step 2: Run linter**

Run: `go vet ./internal/domain/...`
Expected: No errors

**Step 3: Final commit for part 1**

```bash
git add -A
git commit -m "feat(permissions): complete data models for security permissions

- Add OrgRole enum (admin, sme_curator, project_lead, member)
- Add ProjectRole enum with hierarchy (owner > editor > approver > viewer)
- Add Organization model with mandatory knowledge support
- Add OrgMembership model for org-level access
- Add ProjectMembership model for project-level access
- Add MarketplaceEnablement for tracking enabled marketplace items
- All models include validation and Firestore struct tags"
```

---

## Summary

After completing Part 1, you will have:

**Created Files:**
- `internal/domain/permissions.go` - All permission domain models
- `internal/domain/permissions_test.go` - Comprehensive test coverage

**Models Implemented:**
- `OrgRole` enum with 4 roles and validation
- `ProjectRole` enum with 4 roles, hierarchy, and validation
- `Organization` struct with mandatory knowledge support
- `OrgMembership` struct for org membership tracking
- `ProjectMembership` struct for project membership tracking
- `MarketplaceEnablement` struct for marketplace item tracking

**Next:** Proceed to [02-org-permissions.md](./02-org-permissions.md)
