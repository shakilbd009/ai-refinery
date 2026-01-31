# Part 1: Sandbox Data Models

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create domain models for sandbox settings and execution logging with validation.

**Architecture:** Follow existing domain model patterns in `internal/domain/` - JSON struct tags, enum types with `IsValid()` methods, `Validate()` methods on models.

**Tech Stack:** Go, following patterns from `internal/domain/permissions.go`

---

## Task 1: Add Docker SDK Dependency

**Files:**
- Modify: `go.mod`
- Modify: `go.sum`

**Step 1: Add Docker SDK**

```bash
cd /Users/shakilakram/projects/agentic-platform && go get github.com/docker/docker/client@latest
```

**Step 2: Verify dependency is added**

Run: `grep -q "docker/docker" go.mod && echo "SUCCESS" || echo "FAILED"`
Expected: SUCCESS

**Step 3: Commit**

```bash
git add go.mod go.sum
git commit -m "chore: add Docker SDK dependency for sandbox execution"
```

---

## Task 2: Create OrgSandboxSettings Model

**Files:**
- Create: `internal/domain/sandbox.go`
- Test: `internal/domain/sandbox_test.go`

**Step 1: Write the failing test**

```go
// internal/domain/sandbox_test.go
package domain

import (
	"testing"
)

func TestOrgSandboxSettings_Validate(t *testing.T) {
	tests := []struct {
		name    string
		setting OrgSandboxSettings
		wantErr bool
	}{
		{
			name: "valid defaults",
			setting: OrgSandboxSettings{
				OrgID:           "org-123",
				MemoryLimitMB:   512,
				CPUCores:        1.0,
				TimeoutSeconds:  60,
				DiskLimitMB:     100,
				MaxProcesses:    50,
				EnabledRuntimes: []string{"node", "python"},
			},
			wantErr: false,
		},
		{
			name: "missing org id",
			setting: OrgSandboxSettings{
				MemoryLimitMB: 512,
			},
			wantErr: true,
		},
		{
			name: "memory too low",
			setting: OrgSandboxSettings{
				OrgID:         "org-123",
				MemoryLimitMB: 100, // min is 256
			},
			wantErr: true,
		},
		{
			name: "memory too high",
			setting: OrgSandboxSettings{
				OrgID:         "org-123",
				MemoryLimitMB: 5000, // max is 4096
			},
			wantErr: true,
		},
		{
			name: "timeout too short",
			setting: OrgSandboxSettings{
				OrgID:          "org-123",
				MemoryLimitMB:  512,
				TimeoutSeconds: 10, // min is 30
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.setting.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestNewDefaultOrgSandboxSettings(t *testing.T) {
	settings := NewDefaultOrgSandboxSettings("org-123")

	if settings.OrgID != "org-123" {
		t.Errorf("OrgID = %v, want org-123", settings.OrgID)
	}
	if settings.MemoryLimitMB != 512 {
		t.Errorf("MemoryLimitMB = %v, want 512", settings.MemoryLimitMB)
	}
	if settings.CPUCores != 1.0 {
		t.Errorf("CPUCores = %v, want 1.0", settings.CPUCores)
	}
	if settings.TimeoutSeconds != 60 {
		t.Errorf("TimeoutSeconds = %v, want 60", settings.TimeoutSeconds)
	}
	if settings.DiskLimitMB != 100 {
		t.Errorf("DiskLimitMB = %v, want 100", settings.DiskLimitMB)
	}
	if settings.MaxProcesses != 50 {
		t.Errorf("MaxProcesses = %v, want 50", settings.MaxProcesses)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestOrgSandboxSettings -v`
Expected: FAIL - undefined: OrgSandboxSettings

**Step 3: Write minimal implementation**

```go
// internal/domain/sandbox.go
package domain

import (
	"errors"
	"time"
)

// Resource limit boundaries (per design doc)
const (
	MinMemoryMB  = 256
	MaxMemoryMB  = 4096
	MinCPUCores  = 0.5
	MaxCPUCores  = 4.0
	MinTimeoutS  = 30
	MaxTimeoutS  = 600
	MinDiskMB    = 50
	MaxDiskMB    = 1024
	MinProcesses = 10
	MaxProcesses = 200
)

// OrgSandboxSettings holds sandbox configuration for an organization.
type OrgSandboxSettings struct {
	OrgID           string    `json:"orgId"`
	DisabledTools   []string  `json:"disabledTools"`
	MemoryLimitMB   int       `json:"memoryLimitMb"`
	CPUCores        float64   `json:"cpuCores"`
	TimeoutSeconds  int       `json:"timeoutSeconds"`
	DiskLimitMB     int       `json:"diskLimitMb"`
	MaxProcesses    int       `json:"maxProcesses"`
	EnabledRuntimes []string  `json:"enabledRuntimes"`
	UpdatedAt       time.Time `json:"updatedAt"`
	UpdatedBy       string    `json:"updatedBy"`
}

// NewDefaultOrgSandboxSettings creates settings with default values.
func NewDefaultOrgSandboxSettings(orgID string) *OrgSandboxSettings {
	return &OrgSandboxSettings{
		OrgID:           orgID,
		DisabledTools:   []string{},
		MemoryLimitMB:   512,
		CPUCores:        1.0,
		TimeoutSeconds:  60,
		DiskLimitMB:     100,
		MaxProcesses:    50,
		EnabledRuntimes: []string{"node", "python", "go"},
		UpdatedAt:       time.Now(),
	}
}

// Validate checks that settings are within allowed bounds.
func (s *OrgSandboxSettings) Validate() error {
	if s.OrgID == "" {
		return errors.New("orgId is required")
	}
	if s.MemoryLimitMB < MinMemoryMB || s.MemoryLimitMB > MaxMemoryMB {
		return errors.New("memoryLimitMb must be between 256 and 4096")
	}
	if s.CPUCores < MinCPUCores || s.CPUCores > MaxCPUCores {
		return errors.New("cpuCores must be between 0.5 and 4.0")
	}
	if s.TimeoutSeconds < MinTimeoutS || s.TimeoutSeconds > MaxTimeoutS {
		return errors.New("timeoutSeconds must be between 30 and 600")
	}
	if s.DiskLimitMB < MinDiskMB || s.DiskLimitMB > MaxDiskMB {
		return errors.New("diskLimitMb must be between 50 and 1024")
	}
	if s.MaxProcesses < MinProcesses || s.MaxProcesses > MaxProcesses {
		return errors.New("maxProcesses must be between 10 and 200")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestOrgSandboxSettings -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/domain/sandbox.go internal/domain/sandbox_test.go
git commit -m "feat(domain): add OrgSandboxSettings model with validation"
```

---

## Task 3: Create SandboxExecution Model

**Files:**
- Modify: `internal/domain/sandbox.go`
- Modify: `internal/domain/sandbox_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/domain/sandbox_test.go
func TestSandboxExecutionStatus_IsValid(t *testing.T) {
	tests := []struct {
		status SandboxExecutionStatus
		valid  bool
	}{
		{StatusCompleted, true},
		{StatusTimeout, true},
		{StatusMemoryExceeded, true},
		{StatusKilled, true},
		{StatusPartialComplete, true},
		{SandboxExecutionStatus("invalid"), false},
		{SandboxExecutionStatus(""), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.status), func(t *testing.T) {
			if got := tt.status.IsValid(); got != tt.valid {
				t.Errorf("IsValid() = %v, want %v", got, tt.valid)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/domain/... -run TestSandboxExecutionStatus -v`
Expected: FAIL - undefined: SandboxExecutionStatus

**Step 3: Write minimal implementation**

```go
// Add to internal/domain/sandbox.go

// SandboxExecutionStatus represents the outcome of a sandbox execution.
type SandboxExecutionStatus string

const (
	StatusCompleted       SandboxExecutionStatus = "completed"
	StatusTimeout         SandboxExecutionStatus = "timeout"
	StatusMemoryExceeded  SandboxExecutionStatus = "memory_exceeded"
	StatusKilled          SandboxExecutionStatus = "killed"
	StatusPartialComplete SandboxExecutionStatus = "partial_completion"
)

// IsValid checks if the status is a valid execution status.
func (s SandboxExecutionStatus) IsValid() bool {
	switch s {
	case StatusCompleted, StatusTimeout, StatusMemoryExceeded, StatusKilled, StatusPartialComplete:
		return true
	}
	return false
}

// SandboxExecution records a single sandbox execution for auditing.
type SandboxExecution struct {
	ID              string                 `json:"id"`
	ProjectID       string                 `json:"projectId"`
	AgentTaskID     string                 `json:"agentTaskId"`
	Runtime         string                 `json:"runtime"`
	Command         string                 `json:"command"`
	MemoryUsedMB    int                    `json:"memoryUsedMb"`
	CPUTimeSeconds  float64                `json:"cpuTimeSeconds"`
	WallTimeSeconds float64                `json:"wallTimeSeconds"`
	ExitCode        int                    `json:"exitCode"`
	Status          SandboxExecutionStatus `json:"status"`
	WarningIssued   bool                   `json:"warningIssued"`
	Stdout          string                 `json:"stdout"`
	Stderr          string                 `json:"stderr"`
	StartedAt       time.Time              `json:"startedAt"`
	EndedAt         time.Time              `json:"endedAt"`
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/domain/... -run TestSandboxExecutionStatus -v`
Expected: PASS

**Step 5: Run all domain tests**

Run: `go test ./internal/domain/... -v`
Expected: All PASS

**Step 6: Commit**

```bash
git add internal/domain/sandbox.go internal/domain/sandbox_test.go
git commit -m "feat(domain): add SandboxExecution model with status enum"
```

---

## Summary

After completing Part 1, you will have:

**Created Files:**
- `internal/domain/sandbox.go` - Sandbox domain models
- `internal/domain/sandbox_test.go` - Test coverage

**Models Implemented:**
- `OrgSandboxSettings` with validation and defaults
- `SandboxExecutionStatus` enum
- `SandboxExecution` struct for audit logging

**Next:** Proceed to [02-repository.md](./02-repository.md)
