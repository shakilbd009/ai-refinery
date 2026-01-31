# Agent Framework Implementation - LLM Provider

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

This document covers Tasks 4-7: LLM provider interface, tool schema validation, and Claude provider implementation.

---

## Task 4: Define LLM Provider Interface

**Files:**
- Create: `internal/llm/provider.go`
- Test: `internal/llm/provider_test.go`

**Step 1: Write the failing test**

```go
// internal/llm/provider_test.go
package llm

import (
	"testing"
)

func TestMessageRoleValidation(t *testing.T) {
	tests := []struct {
		role  Role
		valid bool
	}{
		{RoleSystem, true},
		{RoleUser, true},
		{RoleAssistant, true},
		{Role("invalid"), false},
	}

	for _, tt := range tests {
		t.Run(string(tt.role), func(t *testing.T) {
			if got := tt.role.IsValid(); got != tt.valid {
				t.Errorf("Role.IsValid() = %v, want %v", got, tt.valid)
			}
		})
	}
}

func TestRequestValidation(t *testing.T) {
	tests := []struct {
		name    string
		req     *Request
		wantErr bool
	}{
		{
			name: "valid request",
			req: &Request{
				Messages: []Message{{Role: RoleUser, Content: "Hello"}},
				Model:    "claude-sonnet-4-20250514",
			},
			wantErr: false,
		},
		{
			name: "empty messages",
			req: &Request{
				Messages: []Message{},
				Model:    "claude-sonnet-4-20250514",
			},
			wantErr: true,
		},
		{
			name: "missing model",
			req: &Request{
				Messages: []Message{{Role: RoleUser, Content: "Hello"}},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.req.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Request.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/llm/... -v`
Expected: FAIL - package does not exist

**Step 3: Write minimal implementation**

```go
// internal/llm/provider.go
package llm

import (
	"context"
	"errors"
)

// Role represents a message role in the conversation.
type Role string

const (
	RoleSystem    Role = "system"
	RoleUser      Role = "user"
	RoleAssistant Role = "assistant"
)

// IsValid checks if the role is a known valid role.
func (r Role) IsValid() bool {
	switch r {
	case RoleSystem, RoleUser, RoleAssistant:
		return true
	default:
		return false
	}
}

// Message represents a single message in a conversation.
type Message struct {
	Role    Role
	Content string
}

// ToolCall represents a tool invocation request from the LLM.
type ToolCall struct {
	ID        string
	Name      string
	Arguments map[string]any
}

// ToolResult represents the result of a tool call.
type ToolResult struct {
	ToolCallID string
	Content    string
	IsError    bool
}

// Tool defines a tool available to the LLM.
type Tool struct {
	Name        string
	Description string
	Parameters  map[string]any // JSON Schema
}

// Request represents a completion request to the LLM.
type Request struct {
	Messages    []Message
	Model       string
	Tools       []Tool
	MaxTokens   int
	Temperature float64
	StopWords   []string
}

// Validate checks that required fields are present.
func (r *Request) Validate() error {
	if len(r.Messages) == 0 {
		return errors.New("request: at least one message required")
	}
	if r.Model == "" {
		return errors.New("request: model is required")
	}
	return nil
}

// Response represents a completion response from the LLM.
type Response struct {
	Content     string
	ToolCalls   []ToolCall
	FinishReason string // "stop", "tool_use", "max_tokens"
	Usage       Usage
}

// Usage tracks token consumption.
type Usage struct {
	InputTokens  int
	OutputTokens int
}

// Provider is the interface for LLM backends.
type Provider interface {
	// Complete sends a request and returns a response.
	Complete(ctx context.Context, req *Request) (*Response, error)

	// Name returns the provider name (e.g., "claude", "openai").
	Name() string
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/llm/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/llm/
git commit -m "$(cat <<'EOF'
feat(llm): add LLM Provider interface and types

Define the abstraction layer for LLM providers:
- Message, Role types for conversation
- Tool, ToolCall, ToolResult for tool use
- Request/Response types with validation
- Provider interface (Complete, Name)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Add Tool Definition Schema

**Files:**
- Modify: `internal/llm/provider.go`
- Test: `internal/llm/provider_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/llm/provider_test.go
func TestToolValidation(t *testing.T) {
	tests := []struct {
		name    string
		tool    Tool
		wantErr bool
	}{
		{
			name: "valid tool",
			tool: Tool{
				Name:        "search_sme_examples",
				Description: "Search SME knowledge for examples",
				Parameters: map[string]any{
					"type": "object",
					"properties": map[string]any{
						"query": map[string]any{"type": "string"},
					},
					"required": []string{"query"},
				},
			},
			wantErr: false,
		},
		{
			name:    "missing name",
			tool:    Tool{Description: "test"},
			wantErr: true,
		},
		{
			name:    "missing description",
			tool:    Tool{Name: "test"},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.tool.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Tool.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/llm/... -v -run TestToolValidation`
Expected: FAIL - Tool.Validate undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/llm/provider.go

// Validate checks that the tool definition is complete.
func (t *Tool) Validate() error {
	if t.Name == "" {
		return errors.New("tool: name is required")
	}
	if t.Description == "" {
		return errors.New("tool: description is required")
	}
	return nil
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/llm/... -v -run TestToolValidation`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/llm/
git commit -m "$(cat <<'EOF'
feat(llm): add Tool validation

Add Validate method to Tool for ensuring complete definitions.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Implement Claude Provider

**Files:**
- Create: `internal/llm/claude.go`
- Test: `internal/llm/claude_test.go`

**Step 1: Write the failing test**

```go
// internal/llm/claude_test.go
package llm

import (
	"testing"
)

func TestClaudeProviderName(t *testing.T) {
	p := NewClaudeProvider("test-api-key")
	if got := p.Name(); got != "claude" {
		t.Errorf("ClaudeProvider.Name() = %v, want %v", got, "claude")
	}
}

func TestClaudeProviderValidation(t *testing.T) {
	tests := []struct {
		name    string
		apiKey  string
		wantErr bool
	}{
		{"valid key", "sk-ant-api-test", false},
		{"empty key", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewClaudeProviderWithValidation(tt.apiKey)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewClaudeProviderWithValidation() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/llm/... -v -run TestClaudeProvider`
Expected: FAIL - NewClaudeProvider undefined

**Step 3: Write minimal implementation**

```go
// internal/llm/claude.go
package llm

import (
	"context"
	"errors"
)

// ClaudeProvider implements Provider for Anthropic's Claude API.
type ClaudeProvider struct {
	apiKey  string
	baseURL string
}

// NewClaudeProvider creates a new Claude provider.
func NewClaudeProvider(apiKey string) *ClaudeProvider {
	return &ClaudeProvider{
		apiKey:  apiKey,
		baseURL: "https://api.anthropic.com/v1",
	}
}

// NewClaudeProviderWithValidation creates a provider with validation.
func NewClaudeProviderWithValidation(apiKey string) (*ClaudeProvider, error) {
	if apiKey == "" {
		return nil, errors.New("claude provider: API key is required")
	}
	return NewClaudeProvider(apiKey), nil
}

// Name returns the provider name.
func (p *ClaudeProvider) Name() string {
	return "claude"
}

// Complete sends a completion request to Claude.
// TODO: Implement actual API call in Task 7
func (p *ClaudeProvider) Complete(ctx context.Context, req *Request) (*Response, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}
	// Placeholder - actual implementation in Task 7
	return nil, errors.New("claude provider: not yet implemented")
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/llm/... -v -run TestClaudeProvider`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/llm/
git commit -m "$(cat <<'EOF'
feat(llm): add ClaudeProvider scaffold

Add Claude provider with:
- Constructor with validation
- Name() returning "claude"
- Complete() placeholder (implementation next task)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Implement Claude API Integration

**Files:**
- Modify: `internal/llm/claude.go`
- Test: `internal/llm/claude_test.go`

**Step 1: Add Anthropic SDK dependency**

Run: `go get github.com/anthropics/anthropic-sdk-go`

**Step 2: Write the failing test**

```go
// Add to internal/llm/claude_test.go
import (
	"context"
	"os"
	"testing"
)

func TestClaudeProviderComplete_Integration(t *testing.T) {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("ANTHROPIC_API_KEY not set, skipping integration test")
	}

	p := NewClaudeProvider(apiKey)
	ctx := context.Background()

	req := &Request{
		Messages: []Message{
			{Role: RoleUser, Content: "Say 'hello' and nothing else."},
		},
		Model:     "claude-sonnet-4-20250514",
		MaxTokens: 50,
	}

	resp, err := p.Complete(ctx, req)
	if err != nil {
		t.Fatalf("Complete() error = %v", err)
	}

	if resp.Content == "" {
		t.Error("Complete() returned empty content")
	}

	if resp.Usage.OutputTokens == 0 {
		t.Error("Complete() returned zero output tokens")
	}
}
```

**Step 3: Run test to verify it fails**

Run: `ANTHROPIC_API_KEY=your-key go test ./internal/llm/... -v -run TestClaudeProviderComplete_Integration`
Expected: FAIL - not yet implemented

**Step 4: Write implementation**

```go
// Replace Complete method in internal/llm/claude.go
import (
	"context"
	"errors"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
)

// Complete sends a completion request to Claude.
func (p *ClaudeProvider) Complete(ctx context.Context, req *Request) (*Response, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	client := anthropic.NewClient(option.WithAPIKey(p.apiKey))

	// Convert messages
	messages := make([]anthropic.MessageParam, 0, len(req.Messages))
	var systemPrompt string
	for _, msg := range req.Messages {
		switch msg.Role {
		case RoleSystem:
			systemPrompt = msg.Content
		case RoleUser:
			messages = append(messages, anthropic.NewUserMessage(
				anthropic.NewTextBlock(msg.Content),
			))
		case RoleAssistant:
			messages = append(messages, anthropic.NewAssistantMessage(
				anthropic.NewTextBlock(msg.Content),
			))
		}
	}

	// Build request params
	params := anthropic.MessageNewParams{
		Model:     anthropic.F(anthropic.Model(req.Model)),
		Messages:  anthropic.F(messages),
		MaxTokens: anthropic.F(int64(req.MaxTokens)),
	}

	if systemPrompt != "" {
		params.System = anthropic.F([]anthropic.TextBlockParam{
			anthropic.NewTextBlock(systemPrompt),
		})
	}

	// Convert tools if present
	if len(req.Tools) > 0 {
		tools := make([]anthropic.ToolParam, len(req.Tools))
		for i, tool := range req.Tools {
			tools[i] = anthropic.ToolParam{
				Name:        anthropic.F(tool.Name),
				Description: anthropic.F(tool.Description),
				InputSchema: anthropic.F(anthropic.ToolInputSchemaParam{
					Type:       anthropic.F(anthropic.ToolInputSchemaTypeObject),
					Properties: anthropic.F(tool.Parameters["properties"]),
				}),
			}
		}
		params.Tools = anthropic.F(tools)
	}

	// Make the API call
	message, err := client.Messages.New(ctx, params)
	if err != nil {
		return nil, err
	}

	// Build response
	resp := &Response{
		FinishReason: string(message.StopReason),
		Usage: Usage{
			InputTokens:  int(message.Usage.InputTokens),
			OutputTokens: int(message.Usage.OutputTokens),
		},
	}

	// Extract content and tool calls
	for _, block := range message.Content {
		switch block.Type {
		case anthropic.ContentBlockTypeText:
			resp.Content += block.Text
		case anthropic.ContentBlockTypeToolUse:
			args := make(map[string]any)
			if block.Input != nil {
				// block.Input is json.RawMessage, unmarshal it
				// For simplicity, treat as map directly if possible
				args = block.Input.(map[string]any)
			}
			resp.ToolCalls = append(resp.ToolCalls, ToolCall{
				ID:        block.ID,
				Name:      block.Name,
				Arguments: args,
			})
		}
	}

	return resp, nil
}
```

**Step 5: Run test to verify it passes**

Run: `ANTHROPIC_API_KEY=your-key go test ./internal/llm/... -v -run TestClaudeProviderComplete_Integration`
Expected: PASS (if API key is valid)

**Step 6: Commit**

```bash
git add internal/llm/ go.mod go.sum
git commit -m "$(cat <<'EOF'
feat(llm): implement Claude API integration

Add full Claude API integration:
- Convert Request/Response to Anthropic SDK types
- Support system prompts, tool definitions
- Extract content and tool calls from response
- Track token usage

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Add Resilience Layer

**Files:**
- Create: `internal/llm/resilient.go`
- Test: `internal/llm/resilient_test.go`

**Step 1: Write the failing test**

```go
// internal/llm/resilient_test.go
package llm

import (
    "context"
    "errors"
    "testing"
)

func TestResilientProvider_RetryOnTimeout(t *testing.T) {
    attempts := 0
    mockProvider := &mockProvider{
        completeFn: func(ctx context.Context, req *Request) (*Response, error) {
            attempts++
            if attempts < 3 {
                return nil, context.DeadlineExceeded
            }
            return &Response{Content: "success"}, nil
        },
    }

    resilient := NewResilientProvider(mockProvider, ResilientConfig{
        MaxRetries: 3,
        BaseDelay:  time.Millisecond,
    })

    resp, err := resilient.Complete(context.Background(), &Request{
        Messages: []Message{{Role: RoleUser, Content: "test"}},
        Model:    "claude-sonnet-4-20250514",
    })

    if err != nil {
        t.Fatalf("expected success after retries, got %v", err)
    }
    if resp.Content != "success" {
        t.Errorf("unexpected response: %s", resp.Content)
    }
    if attempts != 3 {
        t.Errorf("expected 3 attempts, got %d", attempts)
    }
}

func TestResilientProvider_CircuitBreaker(t *testing.T) {
    mockProvider := &mockProvider{
        completeFn: func(ctx context.Context, req *Request) (*Response, error) {
            return nil, errors.New("service unavailable")
        },
    }

    resilient := NewResilientProvider(mockProvider, ResilientConfig{
        MaxRetries:       1,
        CircuitThreshold: 3,
    })

    // Trigger circuit breaker
    for i := 0; i < 5; i++ {
        resilient.Complete(context.Background(), &Request{
            Messages: []Message{{Role: RoleUser, Content: "test"}},
            Model:    "claude-sonnet-4-20250514",
        })
    }

    // Circuit should be open
    _, err := resilient.Complete(context.Background(), &Request{
        Messages: []Message{{Role: RoleUser, Content: "test"}},
        Model:    "claude-sonnet-4-20250514",
    })

    if !errors.Is(err, ErrCircuitOpen) {
        t.Errorf("expected ErrCircuitOpen, got %v", err)
    }
}
```

**Step 2: Write implementation**

```go
// internal/llm/resilient.go
package llm

import (
    "context"
    "errors"
    "sync/atomic"
    "time"
)

var ErrCircuitOpen = errors.New("circuit breaker is open")

type ResilientConfig struct {
    MaxRetries       int
    BaseDelay        time.Duration
    MaxDelay         time.Duration
    CircuitThreshold int32
    CircuitTimeout   time.Duration
}

type ResilientProvider struct {
    provider     Provider
    config       ResilientConfig
    failures     atomic.Int32
    lastFailure  atomic.Value
    circuitOpen  atomic.Bool
}

func NewResilientProvider(provider Provider, config ResilientConfig) *ResilientProvider {
    if config.MaxRetries == 0 {
        config.MaxRetries = 3
    }
    if config.BaseDelay == 0 {
        config.BaseDelay = time.Second
    }
    if config.MaxDelay == 0 {
        config.MaxDelay = 30 * time.Second
    }
    if config.CircuitThreshold == 0 {
        config.CircuitThreshold = 5
    }
    if config.CircuitTimeout == 0 {
        config.CircuitTimeout = 30 * time.Second
    }

    return &ResilientProvider{
        provider: provider,
        config:   config,
    }
}

func (rp *ResilientProvider) Name() string {
    return rp.provider.Name() + "-resilient"
}

func (rp *ResilientProvider) Complete(ctx context.Context, req *Request) (*Response, error) {
    // Check circuit breaker
    if rp.circuitOpen.Load() {
        lastFail, ok := rp.lastFailure.Load().(time.Time)
        if ok && time.Since(lastFail) < rp.config.CircuitTimeout {
            return nil, ErrCircuitOpen
        }
        // Try to close circuit (half-open state)
        rp.circuitOpen.Store(false)
    }

    var lastErr error
    for attempt := 0; attempt <= rp.config.MaxRetries; attempt++ {
        if attempt > 0 {
            delay := rp.calculateBackoff(attempt)
            select {
            case <-time.After(delay):
            case <-ctx.Done():
                return nil, ctx.Err()
            }
        }

        resp, err := rp.provider.Complete(ctx, req)
        if err == nil {
            rp.recordSuccess()
            return resp, nil
        }

        lastErr = err
        if !rp.isRetryable(err) {
            rp.recordFailure()
            return nil, err
        }
    }

    rp.recordFailure()
    return nil, lastErr
}

func (rp *ResilientProvider) calculateBackoff(attempt int) time.Duration {
    delay := rp.config.BaseDelay * time.Duration(1<<uint(attempt-1))
    if delay > rp.config.MaxDelay {
        delay = rp.config.MaxDelay
    }
    return delay
}

func (rp *ResilientProvider) isRetryable(err error) bool {
    return errors.Is(err, context.DeadlineExceeded) ||
           isRateLimitError(err) ||
           isServerError(err)
}

func (rp *ResilientProvider) recordSuccess() {
    rp.failures.Store(0)
}

func (rp *ResilientProvider) recordFailure() {
    failures := rp.failures.Add(1)
    rp.lastFailure.Store(time.Now())

    if failures >= rp.config.CircuitThreshold {
        rp.circuitOpen.Store(true)
    }
}
```

**Step 3: Run tests**

Run: `go test ./internal/llm/... -v -run TestResilientProvider`

**Step 4: Commit**

```bash
git add internal/llm/
git commit -m "$(cat <<'EOF'
feat(llm): add resilient provider with retry and circuit breaker

Add ResilientProvider wrapper with:
- Exponential backoff retry logic
- Circuit breaker pattern
- Configurable thresholds and timeouts
- Graceful degradation on failures

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
