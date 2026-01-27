# Workflow Engine Component

## Overview

Design for the workflow engine that orchestrates agent collaboration, phase transitions, human approvals, change management, and multi-user collaboration.

## Design Principles

- **Fixed linear pipeline**: Requirements → Architecture → Code → Security Review
- **Automatic transitions**: Approval triggers progression, no manual "proceed" step
- **Blocking escalations**: Constraint violations must be resolved before continuing
- **In-place changes**: Upstream changes trigger automatic downstream re-work
- **Collaborative with locking**: Multiple users, no conflicts

---

## Workflow Structure

### Fixed Linear Pipeline

Every project follows the same phase sequence:
```
Requirements → Architecture → Code → Security Review
```

No skipping, no reordering. This ensures:
- Users always know what comes next
- Agents always know what came before
- All code is security-reviewed before completion

### Phase Transitions

Automatic on approval. Once all items in a phase are approved:
1. Phase marked complete
2. Next phase initializes
3. Next agent starts with context from previous phase
4. User notified: "Architecture phase started"

### Parallel Tasks Within Phases

Users can split into parallel tasks for larger projects:
- "Split into tasks" creates independent work streams
- Each task gets its own conversation
- All tasks must complete before phase transition

---

## Workflow States

| State | Description |
|-------|-------------|
| `draft` | Project created, workflow not yet started |
| `in_progress` | Agent actively working on current phase |
| `awaiting_review` | Agent finished, artifacts ready for review |
| `awaiting_approval` | User reviewing items in approval checklist |
| `blocked` | Escalation requires user resolution |
| `completed` | All phases done, project finished |
| `cancelled` | User abandoned the project |

---

## Constraint Validation & Escalations

### Validation Flow

```
Agent generates artifact
        ↓
Self-critique (internal)
        ↓
LLM-judge validates against constraints
        ↓
Pass? → Artifact ready for user review
Fail? → Feedback to agent → Retry (max 3)
        ↓
Retries exhausted? → Escalation created
```

### Escalation Resolution Options

| Action | Effect |
|--------|--------|
| Provide Guidance | User explains how to satisfy; agent retries |
| Edit Directly | User modifies artifact; re-validates |
| Override | User approves despite violation (logged) |
| Change Constraint | Redirect to SME Knowledge to adjust rule |

---

## Change Requests & Re-work

### Triggering Changes

Users can request changes to earlier phases while in a later phase:
1. Select item(s) to change in previous phase
2. System shows impact analysis (dependent items)
3. User describes change and confirms
4. Change applied immediately

### Re-work Processing

1. Original item updated
2. Affected downstream items marked `needs_revision`
3. Agent automatically starts revising
4. Revised items go through normal validation
5. Re-approval requests appear in Inbox

---

## Multi-User Collaboration

### Lock Types

| Lock | Scope | Duration |
|------|-------|----------|
| Review lock | Single artifact | While user has item open |
| Task lock | Entire parallel task | While user in conversation |
| Phase lock | Entire phase | During transition (brief) |

### Visibility

All users on a project see:
- Who's currently active and where
- Real-time updates when items approved/rejected
- Lock status on all items

---

## Related ADRs

- [ADR-006: Fixed Linear Pipeline](../../decisions/ADR-006-fixed-linear-pipeline.md)
- [ADR-007: Automatic Phase Transitions](../../decisions/ADR-007-automatic-phase-transitions.md)
- [ADR-008: Blocking Escalations](../../decisions/ADR-008-blocking-escalations.md)
- [ADR-009: Event Sourcing](../../decisions/ADR-009-event-sourcing.md)
