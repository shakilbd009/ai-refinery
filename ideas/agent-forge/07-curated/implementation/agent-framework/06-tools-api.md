# Agent Framework Implementation - Tools & API

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

This document covers Tasks 24-30: Tool registry, SME knowledge tools, API wiring, integration testing, and final documentation.

---

## Task 24: Create Tool Registry

**Files:**
- Create: `internal/tools/registry.go`
- Test: `internal/tools/registry_test.go`

**Step 1: Write the failing test**

```go
// internal/tools/registry_test.go
package tools

import (
	"context"
	"testing"
)

func TestNewRegistry(t *testing.T) {
	r := NewRegistry()
	if r == nil {
		t.Fatal("NewRegistry() returned nil")
	}
}

func TestRegistryRegisterAndGet(t *testing.T) {
	r := NewRegistry()

	tool := &Tool{
		Name:        "search_sme_examples",
		Description: "Search SME knowledge store for examples",
		Handler: func(ctx context.Context, args map[string]any) (any, error) {
			return "result", nil
		},
	}

	r.Register(tool)

	got := r.Get("search_sme_examples")
	if got == nil {
		t.Error("Get() returned nil for registered tool")
	}
	if got.Name != "search_sme_examples" {
		t.Errorf("Got tool name = %v, want search_sme_examples", got.Name)
	}
}

func TestRegistryListForAgent(t *testing.T) {
	r := NewRegistry()

	r.Register(&Tool{Name: "search_sme_examples", AgentTypes: []string{"requirements", "architecture"}})
	r.Register(&Tool{Name: "get_requirements", AgentTypes: []string{"architecture"}})
	r.Register(&Tool{Name: "get_architecture", AgentTypes: []string{"coding"}})

	reqTools := r.ListForAgent("requirements")
	if len(reqTools) != 1 {
		t.Errorf("requirements agent got %d tools, want 1", len(reqTools))
	}

	archTools := r.ListForAgent("architecture")
	if len(archTools) != 2 {
		t.Errorf("architecture agent got %d tools, want 2", len(archTools))
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/tools/... -v`
Expected: FAIL - package does not exist

**Step 3: Write minimal implementation**

```go
// internal/tools/registry.go
package tools

import (
	"context"
	"sync"
)

// ToolHandler is the function signature for tool execution.
type ToolHandler func(ctx context.Context, args map[string]any) (any, error)

// Tool represents a tool available to agents.
type Tool struct {
	Name        string
	Description string
	Parameters  map[string]any // JSON Schema for parameters
	AgentTypes  []string       // Which agent types can use this tool
	Handler     ToolHandler
}

// Registry manages available tools.
type Registry struct {
	mu    sync.RWMutex
	tools map[string]*Tool
}

// NewRegistry creates a new tool registry.
func NewRegistry() *Registry {
	return &Registry{
		tools: make(map[string]*Tool),
	}
}

// Register adds a tool to the registry.
func (r *Registry) Register(tool *Tool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.tools[tool.Name] = tool
}

// Get retrieves a tool by name.
func (r *Registry) Get(name string) *Tool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.tools[name]
}

// ListForAgent returns tools available to a specific agent type.
func (r *Registry) ListForAgent(agentType string) []*Tool {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*Tool
	for _, tool := range r.tools {
		for _, at := range tool.AgentTypes {
			if at == agentType {
				result = append(result, tool)
				break
			}
		}
	}
	return result
}

// Execute runs a tool by name with the given arguments.
func (r *Registry) Execute(ctx context.Context, name string, args map[string]any) (any, error) {
	tool := r.Get(name)
	if tool == nil {
		return nil, &ToolNotFoundError{Name: name}
	}
	return tool.Handler(ctx, args)
}

// ToolNotFoundError indicates a tool was not found.
type ToolNotFoundError struct {
	Name string
}

func (e *ToolNotFoundError) Error() string {
	return "tool not found: " + e.Name
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/tools/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/tools/
git commit -m "$(cat <<'EOF'
feat(tools): add Tool Registry

Add Registry for managing agent tools:
- Register/Get tools by name
- ListForAgent filters by agent type
- Execute runs tool handler with args
- Thread-safe with RWMutex

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 25: Add Tool Parameter Validation

**Files:**
- Modify: `internal/tools/registry.go`
- Test: `internal/tools/registry_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/tools/registry_test.go
func TestToolValidateArgs(t *testing.T) {
	tool := &Tool{
		Name: "search",
		Parameters: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"query": map[string]any{"type": "string"},
				"limit": map[string]any{"type": "integer"},
			},
			"required": []any{"query"},
		},
	}

	tests := []struct {
		name    string
		args    map[string]any
		wantErr bool
	}{
		{
			name:    "valid args",
			args:    map[string]any{"query": "test", "limit": 10},
			wantErr: false,
		},
		{
			name:    "missing required",
			args:    map[string]any{"limit": 10},
			wantErr: true,
		},
		{
			name:    "only required",
			args:    map[string]any{"query": "test"},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tool.ValidateArgs(tt.args)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateArgs() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/tools/... -v -run TestToolValidateArgs`
Expected: FAIL - ValidateArgs undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/tools/registry.go
import "errors"

// ValidateArgs validates arguments against the tool's parameter schema.
func (t *Tool) ValidateArgs(args map[string]any) error {
	if t.Parameters == nil {
		return nil
	}

	// Extract required fields
	required, _ := t.Parameters["required"].([]any)

	// Check required fields are present
	for _, req := range required {
		reqStr, ok := req.(string)
		if !ok {
			continue
		}
		if _, exists := args[reqStr]; !exists {
			return errors.New("missing required parameter: " + reqStr)
		}
	}

	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/tools/... -v -run TestToolValidateArgs`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/tools/
git commit -m "$(cat <<'EOF'
feat(tools): add parameter validation

Add ValidateArgs to Tool:
- Validates required parameters are present
- Returns descriptive error for missing params
- Handles nil Parameters gracefully

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 26: Implement SME Knowledge Tools

**Files:**
- Create: `internal/tools/sme.go`
- Test: `internal/tools/sme_test.go`

**Step 1: Write the failing test**

```go
// internal/tools/sme_test.go
package tools

import (
	"context"
	"testing"
)

func TestSearchSMEExamples(t *testing.T) {
	// Create mock knowledge service
	mockKnowledge := &mockKnowledgeService{
		examples: []Example{
			{ID: "ex-1", Title: "Login Example", Content: "Example login flow"},
			{ID: "ex-2", Title: "Auth Example", Content: "Authentication pattern"},
		},
	}

	tool := NewSearchSMEExamplesTool(mockKnowledge)

	result, err := tool.Handler(context.Background(), map[string]any{
		"query":      "login",
		"agent_type": "requirements",
		"org_id":     "org-1",
	})

	if err != nil {
		t.Fatalf("Handler() error = %v", err)
	}

	examples, ok := result.([]Example)
	if !ok {
		t.Fatalf("Handler() returned %T, want []Example", result)
	}

	if len(examples) == 0 {
		t.Error("Handler() returned no examples")
	}
}

// Mock types for testing
type Example struct {
	ID      string
	Title   string
	Content string
}

type mockKnowledgeService struct {
	examples []Example
}

func (m *mockKnowledgeService) SearchExamples(ctx context.Context, orgID, agentType, query string) ([]Example, error) {
	// Simple filter for testing
	var result []Example
	for _, ex := range m.examples {
		if contains(ex.Title, query) || contains(ex.Content, query) {
			result = append(result, ex)
		}
	}
	return result, nil
}

func contains(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/tools/... -v -run TestSearchSMEExamples`
Expected: FAIL - NewSearchSMEExamplesTool undefined

**Step 3: Write minimal implementation**

```go
// internal/tools/sme.go
package tools

import (
	"context"
)

// KnowledgeService interface for SME knowledge operations.
type KnowledgeService interface {
	SearchExamples(ctx context.Context, orgID, agentType, query string) ([]Example, error)
}

// Example represents an SME example (duplicated for package independence).
type Example struct {
	ID      string
	Title   string
	Content string
}

// NewSearchSMEExamplesTool creates the search_sme_examples tool.
func NewSearchSMEExamplesTool(knowledge KnowledgeService) *Tool {
	return &Tool{
		Name:        "search_sme_examples",
		Description: "Search SME knowledge store for relevant examples",
		Parameters: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"query":      map[string]any{"type": "string", "description": "Search query"},
				"agent_type": map[string]any{"type": "string", "description": "Agent type filter"},
				"org_id":     map[string]any{"type": "string", "description": "Organization ID"},
			},
			"required": []any{"query", "agent_type", "org_id"},
		},
		AgentTypes: []string{"requirements", "architecture", "coding", "security"},
		Handler: func(ctx context.Context, args map[string]any) (any, error) {
			query, _ := args["query"].(string)
			agentType, _ := args["agent_type"].(string)
			orgID, _ := args["org_id"].(string)

			return knowledge.SearchExamples(ctx, orgID, agentType, query)
		},
	}
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/tools/... -v -run TestSearchSMEExamples`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/tools/
git commit -m "$(cat <<'EOF'
feat(tools): add SME knowledge search tool

Add search_sme_examples tool:
- Searches knowledge store for examples
- Filters by org, agent type, query
- Available to all agent types
- Uses KnowledgeService interface

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 27: Add Remaining SME Tools (Completed)

Extended KnowledgeService interface with:
- `GetProjectContext(ctx, orgID, projectID)` - Returns project details
- `GetSimilarProjects(ctx, orgID, projectID, limit)` - Finds similar projects
- `SearchPatterns(ctx, orgID, query)` - Searches design patterns
- `GetRequirements(ctx, orgID, projectID)` - Returns requirements
- `GetArchitecture(ctx, orgID, projectID)` - Returns architecture

Tool constructors:
- `NewGetProjectContextTool()` - All agents
- `NewGetSimilarProjectsTool()` - requirements, architecture, coding
- `NewSearchSMEPatternsTool()` - architecture, coding
- `NewGetRequirementsTool()` - architecture, coding, security
- `NewGetArchitectureTool()` - coding, security

---

## Task 28: Wire Up Agent API Endpoints (Completed)

**Files:**
- `internal/service/agent_service.go` - Agent service
- `internal/api/handlers/agents.go` - HTTP handlers
- `internal/api/routes/routes.go` - Route registration

**Routes implemented:**
```go
// POST /api/v1/orgs/{orgID}/agents/{agentType}/execute
// GET  /api/v1/orgs/{orgID}/agents/{agentType}/status
// GET  /api/v1/orgs/{orgID}/tasks/{taskID}
// GET  /api/v1/orgs/{orgID}/tasks/{taskID}/result
```

---

## Task 29: Integration Testing (Completed)

**File:** `internal/service/integration_test.go`

Tests:
1. `TestWorkflowIntegration` - Full workflow from Requirements to Architecture
2. `TestCrossPhaseArtifactReferences` - Artifact traceability
3. `TestWorkflowWithMultipleTasks` - Sequential task execution

---

## Task 30: Final Wiring and Documentation (Completed)

**Updates:**
- `cmd/api/main.go` - Agents wired via routes.Setup()
- `ARCHITECTURE.md` - Marked Agent Framework as implemented

**Status:**
- Phase 1: Foundation - COMPLETED
- Phase 2: Core Agents - COMPLETED
- Phase 3: Orchestration - IN PROGRESS
- Phase 4: Security & Polish - IN PROGRESS
