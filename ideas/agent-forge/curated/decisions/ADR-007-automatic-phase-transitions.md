# ADR-007: Automatic Phase Transitions

## Status
Accepted

## Context
When a phase completes, the system could:
1. Wait for explicit "proceed" action from user
2. Automatically transition to next phase on approval
3. Require manager approval before transition

## Decision
**Automatic transitions on approval.** Once all items in a phase are approved:

1. Phase marked complete
2. Next phase initializes automatically
3. Next agent starts with context from previous phase
4. User notified: "Architecture phase started"

Approval *is* the signal to continue - no separate "proceed" step.

## Consequences

### Positive
- Frictionless progression through workflow
- No redundant confirmation steps
- Approval already implies user is ready to continue
- Reduces clicks and cognitive overhead

### Negative
- Users cannot pause between phases
- No explicit "I'm ready for next phase" moment
- May feel automatic/rushed to some users

### Mitigations
- Users can take time reviewing before approving final items
- Dashboard shows clear phase indicators
- Users can always pause within a phase (don't approve yet)
- Activity feed shows when transitions happen
