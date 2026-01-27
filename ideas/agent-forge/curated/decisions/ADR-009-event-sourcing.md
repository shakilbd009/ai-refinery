# ADR-009: Event Sourcing for Audit Trail

## Status
Accepted

## Context
The workflow engine needs to track state and support recovery from failures. Options:
1. Current state only - simple but no history
2. Changelog - append changes to log
3. Event sourcing - all state derived from immutable events

## Decision
Use **event sourcing** as the foundation for workflow state:

Every action logged as an immutable event:
```
EVENT: artifact_created
  workflow_id: WF-123
  phase: architecture
  artifact_id: ARCH-5
  timestamp: 2026-01-15T10:32:15Z
  data: { ... }

EVENT: artifact_approved
  workflow_id: WF-123
  artifact_id: ARCH-5
  user_id: sarah@acme.com
  timestamp: 2026-01-15T10:45:22Z
```

Complemented by:
- **Checkpoints**: Workflow state snapshotted at key points
- **Transactional steps**: Each operation atomic (completes or rolls back)

## Consequences

### Positive
- Complete audit trail of all actions
- Workflow state can be rebuilt from events
- Supports debugging and analytics
- Enables point-in-time recovery
- Natural fit for compliance requirements

### Negative
- Storage overhead for event log
- Complexity in state reconstruction
- Must manage event schema evolution

### Mitigations
- Checkpoints enable fast recovery without full replay
- Events can be archived/compacted over time
- Event versioning strategy for schema changes
