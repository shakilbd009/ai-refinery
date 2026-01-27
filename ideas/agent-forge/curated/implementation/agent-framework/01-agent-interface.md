# Agent Framework Implementation - Agent Interface

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

This document covers Tasks 1-3: Agent interface definition, configuration types, and plan/step types with state machine transitions.

---

## Task 1: Define Agent Interface

**Files:**
- Create: `internal/agents/agent.go`
- Test: `internal/agents/agent_test.go`

**Step 1: Write the failing test**

```go
// internal/agents/agent_test.go
package agents

import (
	"testing"
)

func TestAgentStatusString(t *testing.T) {
	tests := []struct {
		status AgentStatus
		want   string
	}{
		{StatusIdle, "idle"},
		{StatusPlanning, "planning"},
		{StatusExecuting, "executing"},
		{StatusWaiting, "waiting"},
		{StatusCritiquing, "critiquing"},
		{StatusComplete, "complete"},
		{StatusError, "error"},
	}

	for _, tt := range tests {
		t.Run(tt.want, func(t *testing.T) {
			if got := tt.status.String(); got != tt.want {
				t.Errorf("AgentStatus.String() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestAgentTypeString(t *testing.T) {
	tests := []struct {
		agentType AgentType
		want      string
	}{
		{TypeRequirements, "requirements"},
		{TypeArchitecture, "architecture"},
		{TypeCoding, "coding"},
		{TypeSecurity, "security"},
	}

	for _, tt := range tests {
		t.Run(tt.want, func(t *testing.T) {
			if got := tt.agentType.String(); got != tt.want {
				t.Errorf("AgentType.String() = %v, want %v", got, tt.want)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestAgentStatusString`
Expected: FAIL - package does not exist

**Step 3: Write minimal implementation**

```go
// internal/agents/agent.go
package agents

import (
	"context"
	"time"
)

// AgentStatus represents the current state of an agent.
type AgentStatus string

const (
	StatusIdle       AgentStatus = "idle"
	StatusPlanning   AgentStatus = "planning"
	StatusExecuting  AgentStatus = "executing"
	StatusWaiting    AgentStatus = "waiting"
	StatusCritiquing AgentStatus = "critiquing"
	StatusComplete   AgentStatus = "complete"
	StatusError      AgentStatus = "error"
)

func (s AgentStatus) String() string {
	return string(s)
}

// AgentType identifies the kind of agent.
type AgentType string

const (
	TypeRequirements AgentType = "requirements"
	TypeArchitecture AgentType = "architecture"
	TypeCoding       AgentType = "coding"
	TypeSecurity     AgentType = "security"
)

func (t AgentType) String() string {
	return string(t)
}

// Agent is the core interface all agents implement.
type Agent interface {
	// Type returns the agent's type.
	Type() AgentType

	// Execute runs the agent on a task and returns structured output.
	Execute(ctx context.Context, task *Task) (*TaskResult, error)

	// Status returns the agent's current status.
	Status() AgentStatus
}

// Task represents work for an agent to perform.
type Task struct {
	ID          string
	WorkflowID  string
	ProjectID   string
	OrgID       string
	Type        string // e.g., "gather_requirements", "refine_story"
	Input       map[string]any
	Context     *TaskContext
	CreatedAt   time.Time
}

// TaskContext provides context from previous phases and conversation.
type TaskContext struct {
	ConversationHistory []Message
	PreviousArtifacts   []ArtifactRef
	SMEKnowledgeIDs     []string
}

// Message represents a conversation turn.
type Message struct {
	Role      string // "user", "assistant", "system"
	Content   string
	Timestamp time.Time
}

// ArtifactRef references an artifact from a previous phase.
type ArtifactRef struct {
	ID    string
	Type  string
	Phase string
}

// TaskResult is the structured output from agent execution.
type TaskResult struct {
	TaskID     string
	Status     string // "success", "needs_review", "escalation"
	Artifacts  []Artifact
	Messages   []Message // Conversation updates
	Metrics    ExecutionMetrics
	Error      *AgentError
}

// Artifact is a structured output piece (user story, architecture decision, etc.).
type Artifact struct {
	ID       string
	Type     string
	Content  map[string]any
	BasedOn  []ArtifactRef // Traceability
	Metadata map[string]string
}

// ExecutionMetrics tracks agent performance.
type ExecutionMetrics struct {
	Duration        time.Duration
	TokensUsed      int
	ToolCallCount   int
	SelfCritiqueRuns int
}

// AgentError provides structured error information.
type AgentError struct {
	Code    string
	Message string
	Details map[string]any
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): add Agent interface and core types

Define the foundational types for the agent framework:
- AgentStatus enum (idle, planning, executing, etc.)
- AgentType enum (requirements, architecture, coding, security)
- Agent interface with Execute, Type, Status methods
- Task, TaskResult, Artifact types for agent I/O

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add Agent Configuration Types

**Files:**
- Modify: `internal/agents/agent.go`
- Test: `internal/agents/agent_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/agents/agent_test.go
func TestAgentConfigValidation(t *testing.T) {
	tests := []struct {
		name    string
		config  AgentConfig
		wantErr bool
	}{
		{
			name: "valid config",
			config: AgentConfig{
				ID:          "agent-1",
				Type:        TypeRequirements,
				LLMProvider: "claude",
				LLMModel:    "claude-sonnet-4-20250514",
			},
			wantErr: false,
		},
		{
			name: "missing ID",
			config: AgentConfig{
				Type:        TypeRequirements,
				LLMProvider: "claude",
				LLMModel:    "claude-sonnet-4-20250514",
			},
			wantErr: true,
		},
		{
			name: "missing LLM provider",
			config: AgentConfig{
				ID:       "agent-1",
				Type:     TypeRequirements,
				LLMModel: "claude-sonnet-4-20250514",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("AgentConfig.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestAgentConfigValidation`
Expected: FAIL - AgentConfig undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/agents/agent.go
import "errors"

// AgentConfig holds configuration for creating an agent.
type AgentConfig struct {
	ID          string
	Type        AgentType
	LLMProvider string // "claude", "openai", "gemini"
	LLMModel    string
	MaxRetries  int
	Timeout     time.Duration
}

// Validate checks that required fields are set.
func (c *AgentConfig) Validate() error {
	if c.ID == "" {
		return errors.New("agent config: ID is required")
	}
	if c.Type == "" {
		return errors.New("agent config: Type is required")
	}
	if c.LLMProvider == "" {
		return errors.New("agent config: LLMProvider is required")
	}
	if c.LLMModel == "" {
		return errors.New("agent config: LLMModel is required")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestAgentConfigValidation`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): add AgentConfig with validation

Add configuration struct for agent initialization with validation
for required fields (ID, Type, LLMProvider, LLMModel).

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add Plan and Step Types

**Files:**
- Modify: `internal/agents/agent.go`
- Test: `internal/agents/agent_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/agents/agent_test.go
func TestPlanStepStatusTransitions(t *testing.T) {
	tests := []struct {
		from    StepStatus
		to      StepStatus
		valid   bool
	}{
		{StepPending, StepRunning, true},
		{StepRunning, StepCompleted, true},
		{StepRunning, StepFailed, true},
		{StepRunning, StepSkipped, true},
		{StepCompleted, StepRunning, false}, // Can't go back
		{StepFailed, StepRunning, true},     // Retry allowed
	}

	for _, tt := range tests {
		name := tt.from.String() + "->" + tt.to.String()
		t.Run(name, func(t *testing.T) {
			step := &PlanStep{Status: tt.from}
			err := step.TransitionTo(tt.to)
			if (err == nil) != tt.valid {
				t.Errorf("TransitionTo() error = %v, valid = %v", err, tt.valid)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestPlanStepStatusTransitions`
Expected: FAIL - StepStatus undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/agents/agent.go

// StepStatus represents the status of a plan step.
type StepStatus string

const (
	StepPending   StepStatus = "pending"
	StepRunning   StepStatus = "running"
	StepCompleted StepStatus = "completed"
	StepFailed    StepStatus = "failed"
	StepSkipped   StepStatus = "skipped"
)

func (s StepStatus) String() string {
	return string(s)
}

// Plan represents an agent's execution plan.
type Plan struct {
	ID        string
	TaskID    string
	Steps     []*PlanStep
	CreatedAt time.Time
	UpdatedAt time.Time
}

// PlanStep represents a single step in the execution plan.
type PlanStep struct {
	ID          string
	Description string
	StepType    string // "tool_call", "reasoning", "critique"
	Status      StepStatus
	Input       map[string]any
	Output      map[string]any
	Error       string
	StartedAt   *time.Time
	CompletedAt *time.Time
}

// TransitionTo moves the step to a new status if valid.
func (s *PlanStep) TransitionTo(newStatus StepStatus) error {
	validTransitions := map[StepStatus][]StepStatus{
		StepPending:   {StepRunning, StepSkipped},
		StepRunning:   {StepCompleted, StepFailed, StepSkipped},
		StepFailed:    {StepRunning}, // Allow retry
		StepCompleted: {},            // Terminal
		StepSkipped:   {},            // Terminal
	}

	allowed := validTransitions[s.Status]
	for _, valid := range allowed {
		if valid == newStatus {
			s.Status = newStatus
			return nil
		}
	}
	return errors.New("invalid step status transition: " + s.Status.String() + " -> " + newStatus.String())
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestPlanStepStatusTransitions`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): add Plan and PlanStep types with state machine

Add execution plan types:
- Plan with ordered steps
- PlanStep with status transitions
- Valid transitions: pending->running->completed/failed/skipped
- Failed steps can retry (failed->running)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
