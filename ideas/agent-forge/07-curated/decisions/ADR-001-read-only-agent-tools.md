# ADR-001: Read-Only Agent Tool Access

## Status
Accepted

## Context
Agents need to gather information to complete their tasks (search documentation, query previous artifacts, retrieve SME knowledge). The question is whether agents should have write capabilities or be restricted to read-only access.

Concerns:
- Agents with write access could make unintended changes
- Users need to maintain control over what gets persisted
- Safety requires a human-in-the-loop for modifications

## Decision
Agents have **read-only** access to information sources. They can:
- Search SME knowledge
- Fetch documentation
- Query previous phase artifacts
- Retrieve similar past projects

Agents cannot:
- Write files
- Call external APIs
- Execute code (except Coding Agent in sandbox)
- Modify any system state

All outputs flow through the approval system. Agents propose, users approve, the system persists.

## Consequences

### Positive
- Safe by default - agents cannot cause unintended side effects
- Users maintain full control over what gets saved
- Clear mental model: agents suggest, humans decide
- Reduces risk of prompt injection leading to harmful actions

### Negative
- Agents cannot autonomously fix issues they discover
- Every change requires user approval, which may slow workflow
- More round-trips between agent and user for iterative refinement

### Mitigations
- Self-critique loop allows agents to improve output before presenting
- Batch approval UI reduces approval fatigue
- Clear escalation path when agents cannot resolve issues
