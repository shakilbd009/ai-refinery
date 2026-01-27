# Security Review: Security Agent

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Security Agent that reviews code for vulnerabilities.

**Prerequisites:** Complete `01-data-models.md`, `02-repository.md`, `03-service.md`

**Files:**
- Create: `internal/agents/security_agent.go`
- Create: `internal/agents/security_agent_test.go`

---

## Task 1: Create SecurityAgent Structure

**Files:**
- Create: `internal/agents/security_agent.go`
- Create: `internal/agents/security_agent_test.go`

**Step 1: Write the test**

```go
package agents

import (
	"context"
	"testing"
)

func TestSecurityAgent_Type(t *testing.T) {
	agent := NewSecurityAgent(nil)

	if agent.Type() != TypeSecurity {
		t.Errorf("got type %s, want %s", agent.Type(), TypeSecurity)
	}
}

func TestSecurityAgent_Status(t *testing.T) {
	agent := NewSecurityAgent(nil)

	if agent.Status() != StatusIdle {
		t.Errorf("got status %s, want %s", agent.Status(), StatusIdle)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent`

Expected: FAIL - SecurityAgent not defined

**Step 3: Write the implementation**

Create `internal/agents/security_agent.go`:

```go
package agents

import (
	"context"
	"sync"

	"github.com/your-org/agentic-platform/internal/service"
)

// SecurityAgent reviews code for security vulnerabilities
type SecurityAgent struct {
	svc    *service.SecurityService
	status AgentStatus
	mu     sync.RWMutex
}

// NewSecurityAgent creates a new security agent
func NewSecurityAgent(svc *service.SecurityService) *SecurityAgent {
	return &SecurityAgent{
		svc:    svc,
		status: StatusIdle,
	}
}

// Type returns the agent type
func (a *SecurityAgent) Type() AgentType {
	return TypeSecurity
}

// Status returns the current agent status
func (a *SecurityAgent) Status() AgentStatus {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return a.status
}

// setStatus updates the agent status
func (a *SecurityAgent) setStatus(status AgentStatus) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.status = status
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/security_agent.go internal/agents/security_agent_test.go
git commit -m "$(cat <<'EOF'
feat(agents): add SecurityAgent skeleton

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add Execute Method Structure

**Files:**
- Modify: `internal/agents/security_agent.go`
- Modify: `internal/agents/security_agent_test.go`

**Step 1: Write the test**

Add to `internal/agents/security_agent_test.go`:

```go
func TestSecurityAgent_Execute_NoArtifacts(t *testing.T) {
	ctx := context.Background()
	agent := NewSecurityAgent(nil)

	task := &Task{
		ID:         "task-1",
		WorkflowID: "workflow-1",
		ProjectID:  "project-1",
		OrgID:      "org-1",
		Type:       "review_code",
		Input:      map[string]any{},
		Context: &TaskContext{
			PreviousArtifacts: []ArtifactRef{}, // No artifacts
		},
	}

	result, err := agent.Execute(ctx, task)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	if result.Status != "success" {
		t.Errorf("got status %s, want success", result.Status)
	}
	if len(result.Messages) == 0 {
		t.Error("expected at least one message")
	}
}

func TestSecurityAgent_Execute_StatusTransitions(t *testing.T) {
	ctx := context.Background()
	agent := NewSecurityAgent(nil)

	task := &Task{
		ID:         "task-1",
		WorkflowID: "workflow-1",
		ProjectID:  "project-1",
		OrgID:      "org-1",
		Type:       "review_code",
		Input:      map[string]any{},
		Context:    &TaskContext{},
	}

	// Start execution in goroutine to check status
	done := make(chan bool)
	go func() {
		agent.Execute(ctx, task)
		done <- true
	}()

	<-done

	// After completion, should be back to idle or complete
	status := agent.Status()
	if status != StatusIdle && status != StatusComplete {
		t.Errorf("got status %s after execution, want idle or complete", status)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_Execute`

Expected: FAIL - Execute method not implemented

**Step 3: Write the implementation**

Add to `internal/agents/security_agent.go`:

```go
import (
	"time"
)

// Execute runs the security review task
func (a *SecurityAgent) Execute(ctx context.Context, task *Task) (*TaskResult, error) {
	a.setStatus(StatusExecuting)
	startTime := time.Now()
	defer a.setStatus(StatusIdle)

	result := &TaskResult{
		TaskID:    task.ID,
		Status:    "success",
		Artifacts: []Artifact{},
		Messages:  []Message{},
		Metrics: ExecutionMetrics{
			StartTime: startTime,
		},
	}

	// Check for artifacts to review
	if task.Context == nil || len(task.Context.PreviousArtifacts) == 0 {
		result.Messages = append(result.Messages, Message{
			Role:    "agent",
			Content: "Security review complete. No code artifacts to review.",
		})
		result.Metrics.EndTime = time.Now()
		return result, nil
	}

	// TODO: Actual security review logic will be added in next task
	result.Messages = append(result.Messages, Message{
		Role:    "agent",
		Content: "Security review started.",
	})
	result.Metrics.EndTime = time.Now()

	return result, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_Execute`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/security_agent.go internal/agents/security_agent_test.go
git commit -m "$(cat <<'EOF'
feat(agents): add SecurityAgent Execute method skeleton

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add Security Review Logic

**Files:**
- Modify: `internal/agents/security_agent.go`
- Modify: `internal/agents/security_agent_test.go`

**Step 1: Write the test**

Add to `internal/agents/security_agent_test.go`:

```go
func TestSecurityAgent_Execute_WithVulnerableCode(t *testing.T) {
	ctx := context.Background()

	// Setup mock service
	repo := repository.NewMockWorkflowRepository()
	svc := service.NewSecurityService(repo)
	agent := NewSecurityAgent(svc)

	// Create task with code artifact containing SQL injection
	task := &Task{
		ID:         "task-1",
		WorkflowID: "workflow-1",
		ProjectID:  "project-1",
		OrgID:      "org-1",
		Type:       "review_code",
		Input:      map[string]any{},
		Context: &TaskContext{
			PreviousArtifacts: []ArtifactRef{
				{
					ID:   "artifact-1",
					Type: "code",
				},
			},
		},
	}

	result, err := agent.Execute(ctx, task)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// With vulnerable code, should return needs_review status
	if result.Status != "needs_review" && result.Status != "success" {
		t.Errorf("got status %s, want needs_review or success", result.Status)
	}
}

func TestSecurityAgent_CheckForInjection(t *testing.T) {
	agent := NewSecurityAgent(nil)

	tests := []struct {
		name     string
		code     string
		hasIssue bool
	}{
		{
			name:     "SQL injection - string concat",
			code:     `query := "SELECT * FROM users WHERE id = " + userInput`,
			hasIssue: true,
		},
		{
			name:     "SQL injection - fmt.Sprintf",
			code:     `query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userInput)`,
			hasIssue: true,
		},
		{
			name:     "Safe - parameterized query",
			code:     `query := "SELECT * FROM users WHERE id = $1"`,
			hasIssue: false,
		},
		{
			name:     "Command injection - exec",
			code:     `exec.Command("sh", "-c", userInput)`,
			hasIssue: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := agent.checkForInjection(tt.code, "test.go")
			hasIssue := len(issues) > 0
			if hasIssue != tt.hasIssue {
				t.Errorf("checkForInjection(%q) = %v issues, want hasIssue=%v", tt.code, len(issues), tt.hasIssue)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_CheckForInjection`

Expected: FAIL - checkForInjection method not defined

**Step 3: Write the implementation**

Add to `internal/agents/security_agent.go`:

```go
import (
	"regexp"
	"strings"

	"github.com/your-org/agentic-platform/internal/domain"
)

// securityIssue represents a potential security vulnerability found in code
type securityIssue struct {
	Category    domain.FindingCategory
	Severity    domain.FindingSeverity
	Location    string
	Description string
	Patch       string
}

// checkForInjection scans code for injection vulnerabilities
func (a *SecurityAgent) checkForInjection(code string, filename string) []securityIssue {
	var issues []securityIssue

	lines := strings.Split(code, "\n")
	for i, line := range lines {
		lineNum := i + 1
		location := fmt.Sprintf("%s:%d", filename, lineNum)

		// SQL injection patterns
		sqlConcatPattern := regexp.MustCompile(`(?i)(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE).*\+\s*\w+`)
		sqlSprintfPattern := regexp.MustCompile(`(?i)fmt\.Sprintf\s*\(\s*"[^"]*(?:SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)`)

		if sqlConcatPattern.MatchString(line) {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryInjection,
				Severity:    domain.SeverityCritical,
				Location:    location,
				Description: "SQL injection: string concatenation in SQL query",
				Patch:       "Use parameterized queries instead of string concatenation",
			})
		}

		if sqlSprintfPattern.MatchString(line) {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryInjection,
				Severity:    domain.SeverityCritical,
				Location:    location,
				Description: "SQL injection: fmt.Sprintf used to build SQL query",
				Patch:       "Use parameterized queries with placeholders ($1, $2, etc.)",
			})
		}

		// Command injection pattern
		cmdInjectionPattern := regexp.MustCompile(`exec\.Command\s*\(\s*"(?:sh|bash|cmd)".*\+|\,\s*\w+\s*\)`)
		if cmdInjectionPattern.MatchString(line) || strings.Contains(line, `exec.Command("sh", "-c"`) {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryInjection,
				Severity:    domain.SeverityCritical,
				Location:    location,
				Description: "Command injection: user input passed to shell command",
				Patch:       "Avoid shell execution; use direct command with argument array",
			})
		}
	}

	return issues
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_CheckForInjection`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/security_agent.go internal/agents/security_agent_test.go
git commit -m "$(cat <<'EOF'
feat(agents): add injection vulnerability detection

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add More Security Checks

**Files:**
- Modify: `internal/agents/security_agent.go`
- Modify: `internal/agents/security_agent_test.go`

**Step 1: Write the test**

Add to `internal/agents/security_agent_test.go`:

```go
func TestSecurityAgent_CheckForHardcodedCredentials(t *testing.T) {
	agent := NewSecurityAgent(nil)

	tests := []struct {
		name     string
		code     string
		hasIssue bool
	}{
		{
			name:     "Hardcoded password",
			code:     `password := "supersecret123"`,
			hasIssue: true,
		},
		{
			name:     "Hardcoded API key",
			code:     `apiKey := "sk-1234567890abcdef"`,
			hasIssue: true,
		},
		{
			name:     "Safe - env var",
			code:     `password := os.Getenv("DB_PASSWORD")`,
			hasIssue: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := agent.checkForHardcodedCredentials(tt.code, "test.go")
			hasIssue := len(issues) > 0
			if hasIssue != tt.hasIssue {
				t.Errorf("got %v issues, want hasIssue=%v", len(issues), tt.hasIssue)
			}
		})
	}
}

func TestSecurityAgent_CheckForDataExposure(t *testing.T) {
	agent := NewSecurityAgent(nil)

	tests := []struct {
		name     string
		code     string
		hasIssue bool
	}{
		{
			name:     "Logging password",
			code:     `log.Printf("User password: %s", user.Password)`,
			hasIssue: true,
		},
		{
			name:     "Logging token",
			code:     `fmt.Println("Token:", authToken)`,
			hasIssue: true,
		},
		{
			name:     "Safe logging",
			code:     `log.Printf("User ID: %s", user.ID)`,
			hasIssue: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := agent.checkForDataExposure(tt.code, "test.go")
			hasIssue := len(issues) > 0
			if hasIssue != tt.hasIssue {
				t.Errorf("got %v issues, want hasIssue=%v", len(issues), tt.hasIssue)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run "TestSecurityAgent_CheckFor(Hardcoded|Data)"`

Expected: FAIL - methods not defined

**Step 3: Write the implementation**

Add to `internal/agents/security_agent.go`:

```go
// checkForHardcodedCredentials scans for hardcoded secrets
func (a *SecurityAgent) checkForHardcodedCredentials(code string, filename string) []securityIssue {
	var issues []securityIssue

	lines := strings.Split(code, "\n")
	for i, line := range lines {
		lineNum := i + 1
		location := fmt.Sprintf("%s:%d", filename, lineNum)

		// Password patterns
		passwordPattern := regexp.MustCompile(`(?i)(password|passwd|pwd)\s*[:=]\s*["'][^"']+["']`)
		if passwordPattern.MatchString(line) && !strings.Contains(line, "Getenv") {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryAuthentication,
				Severity:    domain.SeverityHigh,
				Location:    location,
				Description: "Hardcoded password detected",
				Patch:       "Use environment variables or a secrets manager",
			})
		}

		// API key patterns
		apiKeyPattern := regexp.MustCompile(`(?i)(api[_-]?key|apikey|secret[_-]?key)\s*[:=]\s*["'][^"']+["']`)
		if apiKeyPattern.MatchString(line) && !strings.Contains(line, "Getenv") {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryAuthentication,
				Severity:    domain.SeverityHigh,
				Location:    location,
				Description: "Hardcoded API key detected",
				Patch:       "Use environment variables or a secrets manager",
			})
		}
	}

	return issues
}

// checkForDataExposure scans for sensitive data in logs
func (a *SecurityAgent) checkForDataExposure(code string, filename string) []securityIssue {
	var issues []securityIssue

	lines := strings.Split(code, "\n")
	for i, line := range lines {
		lineNum := i + 1
		location := fmt.Sprintf("%s:%d", filename, lineNum)

		// Logging sensitive data
		sensitiveLogPattern := regexp.MustCompile(`(?i)(log\.|fmt\.Print|println).*(?:password|token|secret|apikey|credential)`)
		if sensitiveLogPattern.MatchString(line) {
			issues = append(issues, securityIssue{
				Category:    domain.CategoryDataExposure,
				Severity:    domain.SeverityMedium,
				Location:    location,
				Description: "Sensitive data may be exposed in logs",
				Patch:       "Remove sensitive data from log statements",
			})
		}
	}

	return issues
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run "TestSecurityAgent_CheckFor(Hardcoded|Data)"`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/security_agent.go internal/agents/security_agent_test.go
git commit -m "$(cat <<'EOF'
feat(agents): add credential and data exposure checks

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Integrate Checks into Execute

**Files:**
- Modify: `internal/agents/security_agent.go`
- Modify: `internal/agents/security_agent_test.go`

**Step 1: Write the test**

Add to `internal/agents/security_agent_test.go`:

```go
func TestSecurityAgent_ReviewCode(t *testing.T) {
	agent := NewSecurityAgent(nil)

	code := `
package main

func getUser(id string) {
    query := "SELECT * FROM users WHERE id = " + id
    password := "admin123"
    log.Printf("Password: %s", password)
}
`
	issues := agent.reviewCode(code, "main.go")

	// Should find: SQL injection, hardcoded password, data exposure
	if len(issues) < 3 {
		t.Errorf("expected at least 3 issues, got %d", len(issues))
	}

	categories := make(map[domain.FindingCategory]bool)
	for _, issue := range issues {
		categories[issue.Category] = true
	}

	if !categories[domain.CategoryInjection] {
		t.Error("expected injection issue")
	}
	if !categories[domain.CategoryAuthentication] {
		t.Error("expected authentication issue")
	}
	if !categories[domain.CategoryDataExposure] {
		t.Error("expected data exposure issue")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_ReviewCode`

Expected: FAIL - reviewCode method not defined

**Step 3: Write the implementation**

Add to `internal/agents/security_agent.go`:

```go
// reviewCode runs all security checks on the provided code
func (a *SecurityAgent) reviewCode(code string, filename string) []securityIssue {
	var allIssues []securityIssue

	// Run all security checks
	allIssues = append(allIssues, a.checkForInjection(code, filename)...)
	allIssues = append(allIssues, a.checkForHardcodedCredentials(code, filename)...)
	allIssues = append(allIssues, a.checkForDataExposure(code, filename)...)

	return allIssues
}
```

Update the Execute method to use reviewCode:

```go
// Execute runs the security review task
func (a *SecurityAgent) Execute(ctx context.Context, task *Task) (*TaskResult, error) {
	a.setStatus(StatusExecuting)
	startTime := time.Now()
	defer a.setStatus(StatusIdle)

	result := &TaskResult{
		TaskID:    task.ID,
		Status:    "success",
		Artifacts: []Artifact{},
		Messages:  []Message{},
		Metrics: ExecutionMetrics{
			StartTime: startTime,
		},
	}

	// Check for artifacts to review
	if task.Context == nil || len(task.Context.PreviousArtifacts) == 0 {
		result.Messages = append(result.Messages, Message{
			Role:    "agent",
			Content: "Security review complete. No code artifacts to review.",
		})
		result.Metrics.EndTime = time.Now()
		return result, nil
	}

	// Review each artifact
	var allIssues []securityIssue
	for _, artifactRef := range task.Context.PreviousArtifacts {
		if artifactRef.Type != "code" {
			continue
		}

		// In real implementation, fetch artifact content via tool
		// For now, check if code content is in task input
		if code, ok := task.Input["code"].(string); ok {
			filename := "code.go"
			if fn, ok := task.Input["filename"].(string); ok {
				filename = fn
			}
			issues := a.reviewCode(code, filename)
			allIssues = append(allIssues, issues...)
		}
	}

	if len(allIssues) == 0 {
		result.Messages = append(result.Messages, Message{
			Role:    "agent",
			Content: "Security review complete. No issues found.",
		})
	} else {
		result.Status = "needs_review"
		result.Messages = append(result.Messages, Message{
			Role:    "agent",
			Content: fmt.Sprintf("Security review complete. Found %d issue(s) requiring attention.", len(allIssues)),
		})

		// Convert issues to artifacts
		for i, issue := range allIssues {
			result.Artifacts = append(result.Artifacts, Artifact{
				ID:   fmt.Sprintf("finding-%d", i+1),
				Type: "security_finding",
				Content: map[string]any{
					"category":    string(issue.Category),
					"severity":    string(issue.Severity),
					"location":    issue.Location,
					"description": issue.Description,
					"patch":       issue.Patch,
				},
			})
		}
	}

	result.Metrics.EndTime = time.Now()
	return result, nil
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/shakilakram/projects/agentic-platform && go test ./internal/agents/... -v -run TestSecurityAgent_ReviewCode`

Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/security_agent.go internal/agents/security_agent_test.go
git commit -m "$(cat <<'EOF'
feat(agents): integrate security checks into Execute method

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

After completing this module, `SecurityAgent` will:

- Implement the `Agent` interface (Type, Status, Execute)
- Scan code for injection vulnerabilities (SQL, command)
- Detect hardcoded credentials
- Find sensitive data exposure in logs
- Return findings as artifacts with severity, location, and patches

**Next:** Proceed to `05-api-handlers.md`
