# ADR-008: Blocking Escalations

## Status
Accepted

## Context
When an agent cannot resolve a constraint violation after retries, the system creates an escalation. Options for handling:
1. Blocking: Workflow stops until user resolves
2. Non-blocking: Workflow continues, escalation queued
3. Auto-skip: Mark as warning and proceed

## Decision
Escalations are **blocking**. Workflow cannot progress past an escalated item until the user resolves it.

Resolution options:
| Action | Effect |
|--------|--------|
| Provide Guidance | User explains how to satisfy; agent retries |
| Edit Directly | User modifies artifact; re-validates |
| Override | User approves despite violation (logged) |
| Change Constraint | Redirect to SME Knowledge to adjust rule |

Override requires a reason and is logged for audit.

## Consequences

### Positive
- No unresolved violations slip through
- Users must consciously decide on constraint conflicts
- Audit trail captures override decisions
- Maintains integrity of SME-defined standards

### Negative
- Single escalation can block entire workflow
- Users must address issues promptly
- May frustrate users who want to "deal with it later"

### Mitigations
- Multiple resolution options (not just "fix it")
- Override path for legitimate exceptions
- Clear escalation UI with full context
- Escalations appear prominently in Inbox
