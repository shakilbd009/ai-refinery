# Agent Framework Implementation - Prompt & Memory

> **Navigation:** [Overview](00-overview.md) | [Agent Interface](01-agent-interface.md) | [LLM Provider](02-llm-provider.md) | [Executor](03-executor.md) | [Prompt & Memory](04-prompt-memory.md) | [Agents](05-agents.md) | [Tools & API](06-tools-api.md)

This document covers Tasks 12-15: 4-layer prompt builder, SME knowledge injection, memory manager, and LLM-based summarization.

---

## Task 12: Create Prompt Builder Structure

**Files:**
- Create: `internal/prompt/builder.go`
- Test: `internal/prompt/builder_test.go`

**Step 1: Write the failing test**

```go
// internal/prompt/builder_test.go
package prompt

import (
	"testing"
)

func TestNewBuilder(t *testing.T) {
	b := NewBuilder()
	if b == nil {
		t.Fatal("NewBuilder() returned nil")
	}
}

func TestBuilderLayers(t *testing.T) {
	b := NewBuilder()

	// Set each layer
	b.SetBase("You are a requirements agent.")
	b.SetTask("Gather requirements for a login feature.")
	b.SetSMEKnowledge("Always include acceptance criteria.")
	b.AddConversation("user", "I need a login page")

	prompt := b.Build()

	if prompt == "" {
		t.Error("Build() returned empty prompt")
	}

	// Verify all layers are present
	if !contains(prompt, "requirements agent") {
		t.Error("prompt missing base layer")
	}
	if !contains(prompt, "login feature") {
		t.Error("prompt missing task layer")
	}
	if !contains(prompt, "acceptance criteria") {
		t.Error("prompt missing SME knowledge layer")
	}
	if !contains(prompt, "login page") {
		t.Error("prompt missing conversation layer")
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsHelper(s, substr))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/prompt/... -v`
Expected: FAIL - package does not exist

**Step 3: Write minimal implementation**

```go
// internal/prompt/builder.go
package prompt

import (
	"strings"
)

// Builder constructs agent prompts in layers.
type Builder struct {
	base         string
	task         string
	smeKnowledge string
	conversation []ConversationTurn
}

// ConversationTurn represents a single message in the conversation.
type ConversationTurn struct {
	Role    string
	Content string
}

// NewBuilder creates a new prompt builder.
func NewBuilder() *Builder {
	return &Builder{
		conversation: make([]ConversationTurn, 0),
	}
}

// SetBase sets Layer 1: Static base prompt for the agent type.
func (b *Builder) SetBase(base string) *Builder {
	b.base = base
	return b
}

// SetTask sets Layer 2: Task-specific instructions.
func (b *Builder) SetTask(task string) *Builder {
	b.task = task
	return b
}

// SetSMEKnowledge sets Layer 3: SME knowledge (guidelines, templates, etc.).
func (b *Builder) SetSMEKnowledge(knowledge string) *Builder {
	b.smeKnowledge = knowledge
	return b
}

// AddConversation adds Layer 4: A conversation turn.
func (b *Builder) AddConversation(role, content string) *Builder {
	b.conversation = append(b.conversation, ConversationTurn{
		Role:    role,
		Content: content,
	})
	return b
}

// Build constructs the final prompt from all layers.
func (b *Builder) Build() string {
	var parts []string

	// Layer 1: Base
	if b.base != "" {
		parts = append(parts, b.base)
	}

	// Layer 2: Task
	if b.task != "" {
		parts = append(parts, "\n## Current Task\n"+b.task)
	}

	// Layer 3: SME Knowledge
	if b.smeKnowledge != "" {
		parts = append(parts, "\n## Guidelines\n"+b.smeKnowledge)
	}

	// Layer 4: Conversation
	if len(b.conversation) > 0 {
		parts = append(parts, "\n## Conversation")
		for _, turn := range b.conversation {
			parts = append(parts, turn.Role+": "+turn.Content)
		}
	}

	return strings.Join(parts, "\n")
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/prompt/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/prompt/
git commit -m "$(cat <<'EOF'
feat(prompt): add 4-layer prompt builder

Add Builder for constructing agent prompts:
- Layer 1: SetBase - static agent identity
- Layer 2: SetTask - task-specific instructions
- Layer 3: SetSMEKnowledge - guidelines/templates
- Layer 4: AddConversation - conversation history
- Build() combines all layers

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Add SME Knowledge Injection

**Files:**
- Modify: `internal/prompt/builder.go`
- Test: `internal/prompt/builder_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/prompt/builder_test.go
func TestBuilderSMEKnowledgeTypes(t *testing.T) {
	b := NewBuilder()

	// Add different SME knowledge types
	b.AddGuideline("must", "All user stories must have acceptance criteria")
	b.AddGuideline("should", "User stories should be independent")
	b.AddTemplate("user_story", "As a {role}, I want {feature}, so that {benefit}")
	b.AddConstraint("No PII in user stories")

	prompt := b.Build()

	if !contains(prompt, "MUST:") {
		t.Error("prompt missing must guideline prefix")
	}
	if !contains(prompt, "SHOULD:") {
		t.Error("prompt missing should guideline prefix")
	}
	if !contains(prompt, "Template:") {
		t.Error("prompt missing template section")
	}
	if !contains(prompt, "Constraint:") {
		t.Error("prompt missing constraint section")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/prompt/... -v -run TestBuilderSMEKnowledgeTypes`
Expected: FAIL - AddGuideline undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/prompt/builder.go

// Guideline represents an SME guideline with priority.
type Guideline struct {
	Priority string // "must", "should", "may"
	Content  string
}

// Template represents an SME template.
type Template struct {
	Name    string
	Content string
}

// Modify Builder to add structured SME knowledge
type Builder struct {
	base         string
	task         string
	smeKnowledge string
	guidelines   []Guideline
	templates    []Template
	constraints  []string
	conversation []ConversationTurn
}

// AddGuideline adds a guideline with priority (must/should/may).
func (b *Builder) AddGuideline(priority, content string) *Builder {
	b.guidelines = append(b.guidelines, Guideline{
		Priority: priority,
		Content:  content,
	})
	return b
}

// AddTemplate adds a named template.
func (b *Builder) AddTemplate(name, content string) *Builder {
	b.templates = append(b.templates, Template{
		Name:    name,
		Content: content,
	})
	return b
}

// AddConstraint adds a constraint to enforce.
func (b *Builder) AddConstraint(content string) *Builder {
	b.constraints = append(b.constraints, content)
	return b
}

// Update Build() to include structured SME knowledge
func (b *Builder) Build() string {
	var parts []string

	// Layer 1: Base
	if b.base != "" {
		parts = append(parts, b.base)
	}

	// Layer 2: Task
	if b.task != "" {
		parts = append(parts, "\n## Current Task\n"+b.task)
	}

	// Layer 3: SME Knowledge (structured)
	if b.smeKnowledge != "" {
		parts = append(parts, "\n## Guidelines\n"+b.smeKnowledge)
	}

	// Guidelines
	if len(b.guidelines) > 0 {
		parts = append(parts, "\n## Guidelines")
		for _, g := range b.guidelines {
			prefix := strings.ToUpper(g.Priority) + ":"
			parts = append(parts, prefix+" "+g.Content)
		}
	}

	// Templates
	if len(b.templates) > 0 {
		parts = append(parts, "\n## Templates")
		for _, t := range b.templates {
			parts = append(parts, "Template: "+t.Name+"\n"+t.Content)
		}
	}

	// Constraints
	if len(b.constraints) > 0 {
		parts = append(parts, "\n## Constraints")
		for _, c := range b.constraints {
			parts = append(parts, "Constraint: "+c)
		}
	}

	// Layer 4: Conversation
	if len(b.conversation) > 0 {
		parts = append(parts, "\n## Conversation")
		for _, turn := range b.conversation {
			parts = append(parts, turn.Role+": "+turn.Content)
		}
	}

	return strings.Join(parts, "\n")
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/prompt/... -v -run TestBuilderSMEKnowledgeTypes`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/prompt/
git commit -m "$(cat <<'EOF'
feat(prompt): add structured SME knowledge injection

Extend Builder with typed SME knowledge:
- AddGuideline(priority, content) - must/should/may rules
- AddTemplate(name, content) - output format templates
- AddConstraint(content) - validation constraints
- Build() formats each type distinctly

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Create Memory Manager

**Files:**
- Create: `internal/memory/manager.go`
- Test: `internal/memory/manager_test.go`

**Step 1: Write the failing test**

```go
// internal/memory/manager_test.go
package memory

import (
	"testing"
	"time"
)

func TestNewManager(t *testing.T) {
	m := NewManager(10) // Keep 10 recent turns
	if m == nil {
		t.Fatal("NewManager() returned nil")
	}
}

func TestManagerAddAndGetRecent(t *testing.T) {
	m := NewManager(3)

	// Add 5 messages
	for i := 0; i < 5; i++ {
		m.Add(Message{
			Role:      "user",
			Content:   "message " + string(rune('0'+i)),
			Timestamp: time.Now(),
		})
	}

	recent := m.GetRecent()
	if len(recent) != 3 {
		t.Errorf("GetRecent() returned %d messages, want 3", len(recent))
	}

	// Should be the last 3 messages (2, 3, 4)
	if recent[0].Content != "message 2" {
		t.Errorf("First recent message = %s, want 'message 2'", recent[0].Content)
	}
}

func TestManagerSummarization(t *testing.T) {
	m := NewManager(3)

	// Add 5 messages to trigger summarization
	for i := 0; i < 5; i++ {
		m.Add(Message{
			Role:      "user",
			Content:   "message " + string(rune('0'+i)),
			Timestamp: time.Now(),
		})
	}

	// Check that older messages were summarized
	summary := m.GetSummary()
	if summary == "" {
		t.Error("GetSummary() returned empty after overflow")
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/memory/... -v`
Expected: FAIL - package does not exist

**Step 3: Write minimal implementation**

```go
// internal/memory/manager.go
package memory

import (
	"strings"
	"sync"
	"time"
)

// Message represents a conversation message.
type Message struct {
	Role      string
	Content   string
	Timestamp time.Time
}

// Manager manages conversation memory with summarization.
type Manager struct {
	mu           sync.RWMutex
	recentLimit  int
	recent       []Message
	summary      string
	summarized   []Message // Messages that have been summarized
}

// NewManager creates a memory manager with the given recent message limit.
func NewManager(recentLimit int) *Manager {
	return &Manager{
		recentLimit: recentLimit,
		recent:      make([]Message, 0, recentLimit),
		summarized:  make([]Message, 0),
	}
}

// Add adds a message to memory, triggering summarization if needed.
func (m *Manager) Add(msg Message) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.recent = append(m.recent, msg)

	// If we exceed the limit, summarize the oldest
	if len(m.recent) > m.recentLimit {
		overflow := m.recent[0 : len(m.recent)-m.recentLimit]
		m.summarized = append(m.summarized, overflow...)
		m.recent = m.recent[len(m.recent)-m.recentLimit:]
		m.updateSummary()
	}
}

// GetRecent returns the recent messages (full fidelity).
func (m *Manager) GetRecent() []Message {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make([]Message, len(m.recent))
	copy(result, m.recent)
	return result
}

// GetSummary returns the summary of older messages.
func (m *Manager) GetSummary() string {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.summary
}

// updateSummary generates a summary from summarized messages.
// In production, this would call an LLM. For now, simple concatenation.
func (m *Manager) updateSummary() {
	if len(m.summarized) == 0 {
		return
	}

	var parts []string
	parts = append(parts, "Previous conversation summary:")
	for _, msg := range m.summarized {
		parts = append(parts, msg.Role+": "+truncate(msg.Content, 100))
	}
	m.summary = strings.Join(parts, "\n")
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

// Clear resets the memory.
func (m *Manager) Clear() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.recent = make([]Message, 0, m.recentLimit)
	m.summarized = make([]Message, 0)
	m.summary = ""
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/memory/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/memory/
git commit -m "$(cat <<'EOF'
feat(memory): add conversation memory manager

Add Manager for conversation history:
- Configurable recent message limit
- Add() triggers summarization when limit exceeded
- GetRecent() returns full-fidelity recent messages
- GetSummary() returns compressed older history
- Thread-safe with RWMutex

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Add LLM-Based Summarization

**Files:**
- Modify: `internal/memory/manager.go`
- Test: `internal/memory/manager_test.go`

**Step 1: Write the failing test**

```go
// Add to internal/memory/manager_test.go
func TestManagerWithLLMSummarizer(t *testing.T) {
	summarizer := &mockSummarizer{
		result: "User discussed login requirements and authentication needs.",
	}
	m := NewManagerWithSummarizer(3, summarizer)

	// Add messages to trigger summarization
	for i := 0; i < 5; i++ {
		m.Add(Message{
			Role:      "user",
			Content:   "message " + string(rune('0'+i)),
			Timestamp: time.Now(),
		})
	}

	summary := m.GetSummary()
	if summary != "User discussed login requirements and authentication needs." {
		t.Errorf("GetSummary() = %s, want mock summary", summary)
	}
}

type mockSummarizer struct {
	result string
}

func (m *mockSummarizer) Summarize(messages []Message) string {
	return m.result
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/memory/... -v -run TestManagerWithLLMSummarizer`
Expected: FAIL - NewManagerWithSummarizer undefined

**Step 3: Write minimal implementation**

```go
// Add to internal/memory/manager.go

// Summarizer generates summaries of conversation history.
type Summarizer interface {
	Summarize(messages []Message) string
}

// Manager - update struct
type Manager struct {
	mu           sync.RWMutex
	recentLimit  int
	recent       []Message
	summary      string
	summarized   []Message
	summarizer   Summarizer
}

// NewManagerWithSummarizer creates a manager with a custom summarizer.
func NewManagerWithSummarizer(recentLimit int, summarizer Summarizer) *Manager {
	return &Manager{
		recentLimit: recentLimit,
		recent:      make([]Message, 0, recentLimit),
		summarized:  make([]Message, 0),
		summarizer:  summarizer,
	}
}

// Update NewManager to use default summarizer
func NewManager(recentLimit int) *Manager {
	return &Manager{
		recentLimit: recentLimit,
		recent:      make([]Message, 0, recentLimit),
		summarized:  make([]Message, 0),
		summarizer:  &defaultSummarizer{},
	}
}

// defaultSummarizer provides simple summarization
type defaultSummarizer struct{}

func (d *defaultSummarizer) Summarize(messages []Message) string {
	if len(messages) == 0 {
		return ""
	}
	var parts []string
	parts = append(parts, "Previous conversation summary:")
	for _, msg := range messages {
		parts = append(parts, msg.Role+": "+truncate(msg.Content, 100))
	}
	return strings.Join(parts, "\n")
}

// Update updateSummary to use summarizer
func (m *Manager) updateSummary() {
	if len(m.summarized) == 0 {
		return
	}
	if m.summarizer != nil {
		m.summary = m.summarizer.Summarize(m.summarized)
	}
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/memory/... -v -run TestManagerWithLLMSummarizer`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/memory/
git commit -m "$(cat <<'EOF'
feat(memory): add Summarizer interface for LLM integration

Add pluggable summarization:
- Summarizer interface for custom implementations
- NewManagerWithSummarizer for dependency injection
- defaultSummarizer for simple concatenation
- Ready for LLM-based summarization

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
