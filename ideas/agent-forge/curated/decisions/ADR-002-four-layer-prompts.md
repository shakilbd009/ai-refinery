# ADR-002: Four-Layer Prompt Composition

## Status
Accepted

## Context
Agent prompts need to include multiple types of context: base identity, current task instructions, organizational knowledge, and conversation history. The question is how to structure prompt construction to balance stability with flexibility.

Options considered:
1. Single monolithic prompt - simple but inflexible
2. Two layers (system + user) - standard but limited
3. Four layers with clear responsibilities - more complex but organized

## Decision
Agent prompts are built in four layers, each adding specificity:

| Layer | Content | Stability |
|-------|---------|-----------|
| Layer 1: Base | Agent identity and core capabilities | Static per agent type |
| Layer 2: Task | Current task-specific instructions | Changes per task |
| Layer 3: SME | Guidelines, templates, patterns from org | Changes per org |
| Layer 4: Conversation | Recent turns + summaries | Changes per message |

## Consequences

### Positive
- Stable identity across all interactions (Layer 1)
- Task-appropriate behavior without redefining core identity (Layer 2)
- Organization standards automatically applied (Layer 3)
- Context preserved across conversation (Layer 4)
- Clear separation makes debugging easier

### Negative
- More complexity in prompt construction
- Must manage layer priorities when they conflict
- Token budget must be allocated across layers

### Mitigations
- Layer 1 is compact (core identity only)
- Layer 3 filters knowledge by relevance to current task
- Layer 4 uses summarization to manage token budget
