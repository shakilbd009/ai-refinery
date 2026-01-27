# Edge Cases Index

Comprehensive catalog of edge cases, failure modes, and mitigations across all AgentForge components.

## Categories

| Category | Description |
|----------|-------------|
| [Agent Execution](./agent-execution.md) | LLM failures, tool errors, context limits, self-critique loops |
| [Workflow States](./workflow-states.md) | Phase transitions, approvals, escalations, change requests |
| [Concurrency](./concurrency.md) | Multi-user collaboration, locking, race conditions |
| [Integrations](./integrations.md) | External services, sandbox, LLM providers |

---

## Critical Edge Cases Summary

### Must Handle (System Breaks Without)

| Edge Case | Component | Mitigation |
|-----------|-----------|------------|
| LLM timeout mid-task | Agent | Checkpoint + retry from last good state |
| Constraint violation loop | Agent | Max 3 retries → escalation |
| Phase approval conflict | Workflow | Last-write-wins with audit |
| Sandbox escape attempt | Security | gVisor syscall filter + no network |
| Cross-tenant query | Security | Hard org boundary at data layer |

### Should Handle (Degraded Experience Without)

| Edge Case | Component | Mitigation |
|-----------|-----------|------------|
| User abandons mid-phase | Workflow | Auto-save, graceful resume |
| Stuck agent (>5 min) | Agent | Status update prompt, manual intervention |
| SME knowledge update during workflow | SME | Snapshot at workflow start |
| Concurrent item edits | Workflow | Optimistic locking + conflict UI |

### Nice to Handle (Polish)

| Edge Case | Component | Mitigation |
|-----------|-----------|------------|
| First-time user confusion | UX | Guided onboarding tour |
| Empty project list | UX | Encouraging empty state |
| Very long artifact content | UX | Pagination, collapsible sections |

---

## Related Documents

- [Threat Model](../security/threat-model.md) - Security-specific edge cases
- [ADRs](../decisions/index.md) - Decisions that address edge cases
