# Agent Framework Implementation - Executor

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

This document covers Tasks 8-11: Executor structure, planning phase, step execution, and self-critique loop.

---

## Task 8: Create Base Executor Structure

**Files:**
- Create: `internal/agents/executor.go`
- Test: `internal/agents/executor_test.go`

**Step 1: Write the failing test**

```go
// internal/agents/executor_test.go
package agents

import (
	"testing"
)

func TestNewExecutor(t *testing.T) {
	config := &ExecutorConfig{
		MaxSelfCritiqueRuns: 2,
		MaxToolRetries:      3,
	}

	exec := NewExecutor(config)
	if exec == nil {
		t.Fatal("NewExecutor() returned nil")
	}

	if exec.config.MaxSelfCritiqueRuns != 2 {
		t.Errorf("MaxSelfCritiqueRuns = %v, want 2", exec.config.MaxSelfCritiqueRuns)
	}
}

func TestExecutorConfigDefaults(t *testing.T) {
	config := &ExecutorConfig{}
	config.ApplyDefaults()

	if config.MaxSelfCritiqueRuns != 2 {
		t.Errorf("MaxSelfCritiqueRuns default = %v, want 2", config.MaxSelfCritiqueRuns)
	}
	if config.MaxToolRetries != 3 {
		t.Errorf("MaxToolRetries default = %v, want 3", config.MaxToolRetries)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestNewExecutor`
Expected: FAIL - Executor undefined

**Step 3: Write minimal implementation**

```go
// internal/agents/executor.go
package agents

import (
	"context"
	"sync"

	"agentic-platform/internal/llm"
)

// ExecutorConfig holds configuration for the executor.
type ExecutorConfig struct {
	MaxSelfCritiqueRuns int
	MaxToolRetries      int
}

// ApplyDefaults sets default values for unset fields.
func (c *ExecutorConfig) ApplyDefaults() {
	if c.MaxSelfCritiqueRuns == 0 {
		c.MaxSelfCritiqueRuns = 2
	}
	if c.MaxToolRetries == 0 {
		c.MaxToolRetries = 3
	}
}

// Executor runs agent tasks through the core execution loop.
type Executor struct {
	config      *ExecutorConfig
	llmProvider llm.Provider
	mu          sync.RWMutex
	status      AgentStatus
}

// NewExecutor creates a new executor with the given config.
func NewExecutor(config *ExecutorConfig) *Executor {
	config.ApplyDefaults()
	return &Executor{
		config: config,
		status: StatusIdle,
	}
}

// SetLLMProvider sets the LLM provider for this executor.
func (e *Executor) SetLLMProvider(provider llm.Provider) {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.llmProvider = provider
}

// Status returns the current executor status.
func (e *Executor) Status() AgentStatus {
	e.mu.RLock()
	defer e.mu.RUnlock()
	return e.status
}

func (e *Executor) setStatus(status AgentStatus) {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.status = status
}

// Execute runs the core agent execution loop.
// TODO: Implement in Tasks 9-11
func (e *Executor) Execute(ctx context.Context, agent Agent, task *Task) (*TaskResult, error) {
	e.setStatus(StatusExecuting)
	defer e.setStatus(StatusComplete)

	// Placeholder - implement core loop in subsequent tasks
	return &TaskResult{
		TaskID: task.ID,
		Status: "success",
	}, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestNewExecutor`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): add Executor structure

Add Executor for running agents:
- ExecutorConfig with defaults (MaxSelfCritiqueRuns=2, MaxToolRetries=3)
- Status tracking with thread-safe access
- Execute placeholder (implementation in following tasks)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Implement Planning Phase

**Files:**
- Modify: `internal/agents/executor.go`
- Test: `internal/agents/executor_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/agents/executor_test.go
func TestExecutorGeneratePlan(t *testing.T) {
	exec := NewExecutor(&ExecutorConfig{})

	// Create mock LLM provider
	mockProvider := &mockLLMProvider{
		response: &llm.Response{
			Content: `{"steps": [{"description": "Gather requirements", "type": "reasoning"}]}`,
		},
	}
	exec.SetLLMProvider(mockProvider)

	task := &Task{
		ID:   "task-1",
		Type: "gather_requirements",
	}

	plan, err := exec.generatePlan(context.Background(), task)
	if err != nil {
		t.Fatalf("generatePlan() error = %v", err)
	}

	if len(plan.Steps) == 0 {
		t.Error("generatePlan() returned empty plan")
	}
}

// mockLLMProvider is a test double for llm.Provider
type mockLLMProvider struct {
	response *llm.Response
	err      error
}

func (m *mockLLMProvider) Complete(ctx context.Context, req *llm.Request) (*llm.Response, error) {
	return m.response, m.err
}

func (m *mockLLMProvider) Name() string {
	return "mock"
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestExecutorGeneratePlan`
Expected: FAIL - generatePlan undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/agents/executor.go
import (
	"encoding/json"
	"errors"
	"time"
)

// generatePlan creates an execution plan for the task.
func (e *Executor) generatePlan(ctx context.Context, task *Task) (*Plan, error) {
	e.setStatus(StatusPlanning)

	if e.llmProvider == nil {
		return nil, errors.New("executor: LLM provider not set")
	}

	// Build planning prompt
	planPrompt := buildPlanningPrompt(task)

	req := &llm.Request{
		Messages: []llm.Message{
			{Role: llm.RoleSystem, Content: "You are a planning assistant. Generate a step-by-step execution plan as JSON."},
			{Role: llm.RoleUser, Content: planPrompt},
		},
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 1000,
	}

	resp, err := e.llmProvider.Complete(ctx, req)
	if err != nil {
		return nil, err
	}

	// Parse plan from response
	plan, err := parsePlanFromJSON(resp.Content, task.ID)
	if err != nil {
		return nil, err
	}

	return plan, nil
}

func buildPlanningPrompt(task *Task) string {
	return "Create an execution plan for this task: " + task.Type +
		"\nTask ID: " + task.ID +
		"\nRespond with JSON: {\"steps\": [{\"description\": \"...\", \"type\": \"reasoning|tool_call\"}]}"
}

// planJSON is the expected structure from LLM response
type planJSON struct {
	Steps []struct {
		Description string `json:"description"`
		Type        string `json:"type"`
	} `json:"steps"`
}

func parsePlanFromJSON(content string, taskID string) (*Plan, error) {
	var pj planJSON
	if err := json.Unmarshal([]byte(content), &pj); err != nil {
		return nil, errors.New("executor: failed to parse plan JSON: " + err.Error())
	}

	plan := &Plan{
		ID:        "plan-" + taskID,
		TaskID:    taskID,
		Steps:     make([]*PlanStep, len(pj.Steps)),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	for i, step := range pj.Steps {
		plan.Steps[i] = &PlanStep{
			ID:          plan.ID + "-step-" + string(rune('0'+i)),
			Description: step.Description,
			StepType:    step.Type,
			Status:      StepPending,
		}
	}

	return plan, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestExecutorGeneratePlan`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): implement planning phase

Add generatePlan to Executor:
- Builds planning prompt from task
- Calls LLM to generate step-by-step plan
- Parses JSON response into Plan/PlanStep structures
- Sets executor status to StatusPlanning during operation

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Implement Step Execution

**Files:**
- Modify: `internal/agents/executor.go`
- Test: `internal/agents/executor_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/agents/executor_test.go
func TestExecutorExecuteStep(t *testing.T) {
	exec := NewExecutor(&ExecutorConfig{})
	mockProvider := &mockLLMProvider{
		response: &llm.Response{
			Content: "Step completed successfully",
		},
	}
	exec.SetLLMProvider(mockProvider)

	step := &PlanStep{
		ID:          "step-1",
		Description: "Analyze requirements",
		StepType:    "reasoning",
		Status:      StepPending,
	}

	err := exec.executeStep(context.Background(), step, nil)
	if err != nil {
		t.Fatalf("executeStep() error = %v", err)
	}

	if step.Status != StepCompleted {
		t.Errorf("step.Status = %v, want %v", step.Status, StepCompleted)
	}

	if step.Output == nil {
		t.Error("step.Output is nil")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestExecutorExecuteStep`
Expected: FAIL - executeStep undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/agents/executor.go

// StepContext holds context accumulated during execution.
type StepContext struct {
	Results    map[string]any
	Artifacts  []Artifact
	TokensUsed int
}

// executeStep runs a single plan step.
func (e *Executor) executeStep(ctx context.Context, step *PlanStep, stepCtx *StepContext) error {
	if stepCtx == nil {
		stepCtx = &StepContext{Results: make(map[string]any)}
	}

	// Transition to running
	if err := step.TransitionTo(StepRunning); err != nil {
		return err
	}
	now := time.Now()
	step.StartedAt = &now

	var err error
	switch step.StepType {
	case "reasoning":
		err = e.executeReasoningStep(ctx, step, stepCtx)
	case "tool_call":
		err = e.executeToolCallStep(ctx, step, stepCtx)
	default:
		err = e.executeReasoningStep(ctx, step, stepCtx) // Default to reasoning
	}

	completedAt := time.Now()
	step.CompletedAt = &completedAt

	if err != nil {
		step.Error = err.Error()
		step.TransitionTo(StepFailed)
		return err
	}

	return step.TransitionTo(StepCompleted)
}

func (e *Executor) executeReasoningStep(ctx context.Context, step *PlanStep, stepCtx *StepContext) error {
	req := &llm.Request{
		Messages: []llm.Message{
			{Role: llm.RoleUser, Content: "Execute this step: " + step.Description},
		},
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 2000,
	}

	resp, err := e.llmProvider.Complete(ctx, req)
	if err != nil {
		return err
	}

	step.Output = map[string]any{
		"content": resp.Content,
	}
	stepCtx.TokensUsed += resp.Usage.InputTokens + resp.Usage.OutputTokens
	stepCtx.Results[step.ID] = resp.Content

	return nil
}

func (e *Executor) executeToolCallStep(ctx context.Context, step *PlanStep, stepCtx *StepContext) error {
	// TODO: Implement tool execution in Task 26-27
	return e.executeReasoningStep(ctx, step, stepCtx)
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestExecutorExecuteStep`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): implement step execution

Add executeStep to Executor:
- StepContext for accumulating results
- Status transitions (pending->running->completed/failed)
- Reasoning step execution via LLM
- Tool call step placeholder (implemented later)
- Timing tracking (StartedAt, CompletedAt)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Implement Self-Critique Loop

**Files:**
- Modify: `internal/agents/executor.go`
- Test: `internal/agents/executor_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/agents/executor_test.go
func TestExecutorSelfCritique(t *testing.T) {
	exec := NewExecutor(&ExecutorConfig{MaxSelfCritiqueRuns: 2})
	mockProvider := &mockLLMProvider{
		response: &llm.Response{
			Content: `{"passed": true, "issues": []}`,
		},
	}
	exec.SetLLMProvider(mockProvider)

	artifacts := []Artifact{
		{ID: "art-1", Type: "user_story", Content: map[string]any{"title": "Test"}},
	}

	result, err := exec.selfCritique(context.Background(), artifacts)
	if err != nil {
		t.Fatalf("selfCritique() error = %v", err)
	}

	if !result.Passed {
		t.Error("selfCritique() should pass with no issues")
	}
}

func TestExecutorSelfCritiqueWithRevision(t *testing.T) {
	exec := NewExecutor(&ExecutorConfig{MaxSelfCritiqueRuns: 2})

	callCount := 0
	mockProvider := &mockLLMProviderFunc{
		fn: func(ctx context.Context, req *llm.Request) (*llm.Response, error) {
			callCount++
			if callCount == 1 {
				// First critique: issues found
				return &llm.Response{
					Content: `{"passed": false, "issues": ["Missing acceptance criteria"]}`,
				}, nil
			}
			// Second critique after revision: passed
			return &llm.Response{
				Content: `{"passed": true, "issues": []}`,
			}, nil
		},
	}
	exec.SetLLMProvider(mockProvider)

	artifacts := []Artifact{
		{ID: "art-1", Type: "user_story", Content: map[string]any{"title": "Test"}},
	}

	result, err := exec.selfCritique(context.Background(), artifacts)
	if err != nil {
		t.Fatalf("selfCritique() error = %v", err)
	}

	if result.RevisionCount != 1 {
		t.Errorf("RevisionCount = %v, want 1", result.RevisionCount)
	}
}

type mockLLMProviderFunc struct {
	fn func(ctx context.Context, req *llm.Request) (*llm.Response, error)
}

func (m *mockLLMProviderFunc) Complete(ctx context.Context, req *llm.Request) (*llm.Response, error) {
	return m.fn(ctx, req)
}

func (m *mockLLMProviderFunc) Name() string {
	return "mock"
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/agents/... -v -run TestExecutorSelfCritique`
Expected: FAIL - selfCritique undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/agents/executor.go

// CritiqueResult holds the result of self-critique.
type CritiqueResult struct {
	Passed        bool
	Issues        []string
	RevisionCount int
}

// selfCritique runs the self-critique loop on artifacts.
func (e *Executor) selfCritique(ctx context.Context, artifacts []Artifact) (*CritiqueResult, error) {
	e.setStatus(StatusCritiquing)

	result := &CritiqueResult{}

	for i := 0; i < e.config.MaxSelfCritiqueRuns; i++ {
		critique, err := e.runCritique(ctx, artifacts)
		if err != nil {
			return nil, err
		}

		if critique.Passed {
			result.Passed = true
			return result, nil
		}

		result.Issues = critique.Issues
		result.RevisionCount++

		// Attempt revision
		artifacts, err = e.reviseArtifacts(ctx, artifacts, critique.Issues)
		if err != nil {
			return nil, err
		}
	}

	// Max critiques reached, return last result
	return result, nil
}

type critiqueJSON struct {
	Passed bool     `json:"passed"`
	Issues []string `json:"issues"`
}

func (e *Executor) runCritique(ctx context.Context, artifacts []Artifact) (*critiqueJSON, error) {
	artifactJSON, _ := json.Marshal(artifacts)

	req := &llm.Request{
		Messages: []llm.Message{
			{Role: llm.RoleSystem, Content: `You are a quality reviewer. Review the artifacts for completeness, consistency, and quality.
Respond with JSON: {"passed": true/false, "issues": ["issue1", "issue2"]}`},
			{Role: llm.RoleUser, Content: "Review these artifacts:\n" + string(artifactJSON)},
		},
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 1000,
	}

	resp, err := e.llmProvider.Complete(ctx, req)
	if err != nil {
		return nil, err
	}

	var critique critiqueJSON
	if err := json.Unmarshal([]byte(resp.Content), &critique); err != nil {
		return nil, errors.New("executor: failed to parse critique: " + err.Error())
	}

	return &critique, nil
}

func (e *Executor) reviseArtifacts(ctx context.Context, artifacts []Artifact, issues []string) ([]Artifact, error) {
	artifactJSON, _ := json.Marshal(artifacts)
	issuesJSON, _ := json.Marshal(issues)

	req := &llm.Request{
		Messages: []llm.Message{
			{Role: llm.RoleSystem, Content: "You are revising artifacts to fix identified issues. Return the corrected artifacts as JSON array."},
			{Role: llm.RoleUser, Content: "Artifacts:\n" + string(artifactJSON) + "\n\nIssues to fix:\n" + string(issuesJSON)},
		},
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 2000,
	}

	resp, err := e.llmProvider.Complete(ctx, req)
	if err != nil {
		return nil, err
	}

	var revised []Artifact
	if err := json.Unmarshal([]byte(resp.Content), &revised); err != nil {
		// If parsing fails, return original with note
		return artifacts, nil
	}

	return revised, nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/agents/... -v -run TestExecutorSelfCritique`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/agents/
git commit -m "$(cat <<'EOF'
feat(agents): implement self-critique loop

Add self-critique to Executor:
- runCritique sends artifacts to LLM for review
- Parses passed/issues from JSON response
- reviseArtifacts attempts to fix identified issues
- Loop runs up to MaxSelfCritiqueRuns times
- Tracks revision count in CritiqueResult

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
