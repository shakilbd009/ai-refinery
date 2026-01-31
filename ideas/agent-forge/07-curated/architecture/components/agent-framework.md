# Agent Framework Component

## Overview

Design for how agents work internally: execution model, tool access, prompt construction, memory management, error handling, and SME knowledge integration.

## Design Principles

- **Tool-using reasoners**: Agents gather information via tools, not just generate text
- **Read-only access**: Agents cannot write or modify - all changes flow through user approval
- **Hybrid planning**: Structured plans that adapt reactively to unexpected situations
- **Layered prompts**: Base identity + task context + SME knowledge + conversation
- **Self-improvement**: Agents critique their own output before presenting to users

---

## Execution Model

### Core Loop

1. Agent receives a task (e.g., "Gather requirements for this project")
2. Agent generates an initial plan based on task type and context
3. For each plan step:
   - Execute the step (tool calls or LLM reasoning)
   - Observe the result
   - Decide: continue plan, adapt plan, or mark complete
4. Self-critique the output before returning
5. Return structured JSON artifacts

### Planning Flexibility

The initial plan provides structure, but agents adapt reactively:
- Tool call fails → reassess and try alternative
- Unexpected information → revise remaining steps
- User provides new context → incorporate and continue

### Progress Reporting

| Internal State | User Sees |
|----------------|-----------|
| `planning` | "Analyzing your request..." |
| `executing` + tool call | "Searching documentation..." |
| `executing` + reasoning | "Generating user stories..." |
| `critiquing` | "Reviewing for quality..." |
| `complete` | "Ready for your review" |

---

## Agent-Specific Tools

Each agent type has a tailored read-only toolset.

### Requirements Agent
| Tool | Purpose |
|------|---------|
| `search_sme_examples` | Find relevant examples from SME knowledge |
| `get_similar_projects` | Retrieve requirements from similar past projects |
| `get_project_context` | Read project name, description, existing artifacts |

### Architecture Agent
| Tool | Purpose |
|------|---------|
| `get_requirements` | Query approved requirements (selective retrieval) |
| `search_sme_patterns` | Find architectural patterns and templates |
| `fetch_tech_docs` | Retrieve documentation for approved technologies |

### Coding Agent
| Tool | Purpose |
|------|---------|
| `get_architecture` | Query approved architecture decisions |
| `search_sme_code` | Find code examples and templates |
| `fetch_library_docs` | Retrieve library documentation |
| `execute_in_sandbox` | Run code in isolated container |
| `get_applicable_patterns` | Retrieve SME-defined code patterns |

### Security Agent
| Tool | Purpose |
|------|---------|
| `get_code_artifacts` | Retrieve all code from Code phase |
| `get_architecture` | Understand intended security model |
| `search_sme_security` | Find org-specific security rules |
| `propose_fix` | Submit a code patch for user approval |

---

## Phase Handoffs

### Selective Retrieval Model

Agents don't receive all project data upfront. They query what they need:

1. User approves previous phase → artifacts finalized
2. Next agent initializes with minimal context
3. Agent generates plan, calling retrieval tools for relevant artifacts
4. Retrieved artifacts injected into context for generation

### Cross-Phase References

Artifacts include `basedOn` references for impact analysis:
```json
{
  "type": "APIEndpoint",
  "name": "/users/create",
  "basedOn": {
    "requirements": ["REQ-12", "REQ-15"],
    "architecture": ["ARCH-3"]
  }
}
```

---

## Agent States

| State | Description |
|-------|-------------|
| `idle` | No active task, ready to receive work |
| `planning` | Generating execution plan |
| `executing` | Running plan steps |
| `waiting` | Blocked on external input |
| `critiquing` | Self-reviewing output |
| `complete` | Task finished, artifacts ready |
| `error` | Unrecoverable error, escalation needed |

---

---

## Event Emission

Agents communicate with the rest of the system via the Event Bus rather than direct calls.

### Events Published

| Event | When | Payload |
|-------|------|---------|
| `AgentTaskStarted` | Task begins execution | taskId, agentType, projectId |
| `AgentTaskProgress` | State changes | taskId, state, message |
| `AgentTaskCompleted` | Task finishes successfully | taskId, artifacts[], tokenUsage |
| `AgentTaskFailed` | Unrecoverable error | taskId, error, retryable |
| `AgentToolCalled` | Tool invocation | taskId, toolName, args |

### Event Emission Pattern

```go
func (e *AgentExecutor) Execute(ctx context.Context, task *Task) error {
    // Publish start event
    e.eventBus.Publish(ctx, &AgentTaskStartedEvent{
        TaskID:    task.ID,
        AgentType: task.AgentType,
        ProjectID: task.ProjectID,
    })

    // Execute with progress updates
    result, err := e.runWithProgress(ctx, task)
    if err != nil {
        e.eventBus.Publish(ctx, &AgentTaskFailedEvent{
            TaskID:    task.ID,
            Error:     err.Error(),
            Retryable: isRetryable(err),
        })
        return err
    }

    // Publish completion
    e.eventBus.Publish(ctx, &AgentTaskCompletedEvent{
        TaskID:     task.ID,
        Artifacts:  result.Artifacts,
        TokenUsage: result.Usage,
    })

    return nil
}
```

---

## Related ADRs

- [ADR-001: Read-Only Agent Tool Access](../../decisions/ADR-001-read-only-agent-tools.md)
- [ADR-002: Four-Layer Prompt Composition](../../decisions/ADR-002-four-layer-prompts.md)
- [ADR-003: Conversation Summarization](../../decisions/ADR-003-conversation-summarization.md)
- [ADR-004: Tiered Error Response](../../decisions/ADR-004-tiered-error-response.md)
- [ADR-005: Self-Critique Before Validation](../../decisions/ADR-005-self-critique-validation.md)
- [ADR-020: Event-Driven Decoupling](../../decisions/ADR-020-event-driven-decoupling.md)
- [ADR-021: LLM Provider Resilience](../../decisions/ADR-021-llm-provider-resilience.md)
