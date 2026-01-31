# Edge Cases: Workflow States

## Phase Transitions

### All Items Approved But Transition Fails

**Trigger:** DB write fails during transition

**Impact:** Inconsistent state (approved but not transitioned)

**Mitigation:**
- Transaction wraps approval + transition
- On failure, rollback approval status
- Retry transaction once
- Surface error if still fails

### Partial Approval Before User Leaves

**Trigger:** User approves some items, leaves session

**Impact:** Phase stuck in partial state

**Mitigation:**
- Approvals saved immediately (not batched)
- Resume shows remaining unapproved items
- No timeout on partial approval
- Inbox shows "X items remaining"

### User Tries to Skip Phase

**Trigger:** User attempts to access future phase

**Impact:** Potential incomplete requirements

**Mitigation:**
- UI dims future phases
- API rejects future phase access
- Message: "Complete [current phase] first"

---

## Approvals

### Reject Without Feedback

**Trigger:** User clicks reject but provides no feedback

**Impact:** Agent doesn't know what to fix

**Mitigation:**
- Require minimum feedback (can be brief)
- Suggest common reasons as quick-select
- "What should change?" prompt

### Approve Then Change Mind

**Trigger:** User approves, then wants to undo

**Impact:** May have triggered downstream actions

**Mitigation:**
- Grace period (30s) for undo
- After grace period, use Change Request flow
- Show "Undo" button briefly after approval

### Batch Approve with Hidden Issues

**Trigger:** User approves all without reviewing each

**Impact:** Issues slip through

**Mitigation:**
- "Review each" prompt for first-time users
- Show count of items not individually viewed
- Allow but track batch approvals

---

## Escalations

### User Ignores Escalation

**Trigger:** Escalation sits unresolved for days

**Impact:** Workflow blocked indefinitely

**Mitigation:**
- Daily email reminder after 24h
- Escalation age shown in Inbox (with warning colors)
- Org admin can see blocked workflows
- No auto-timeout (user must decide)

### Override Abuse

**Trigger:** User overrides every escalation without fixing

**Impact:** Constraint system becomes useless

**Mitigation:**
- All overrides logged with reason
- Admin dashboard shows override frequency
- Org can set max overrides per project
- Review required if threshold exceeded

### Escalation During Phase Transition

**Trigger:** Escalation created while transition in progress

**Impact:** Race condition

**Mitigation:**
- Transitions check for pending escalations
- New escalation blocks ongoing transition
- Transaction ensures consistency

---

## Change Requests

### Change Request Creates Cascade

**Trigger:** Requirement change invalidates 50% of architecture

**Impact:** Massive rework

**Mitigation:**
- Impact analysis before confirmation
- Show: "This affects X items in Architecture, Y items in Code"
- User confirms with full knowledge
- Consider: "Too late to change" warning after Code phase

### Conflicting Change Requests

**Trigger:** Two users submit conflicting changes

**Impact:** Confusion about requirements

**Mitigation:**
- Change requests processed sequentially
- Second request sees updated state
- If conflict detected, merge or reject

### Change Request During Agent Work

**Trigger:** User submits change while agent is working

**Impact:** Agent working on stale requirements

**Mitigation:**
- Lock phase during agent work
- Change request queued until agent completes
- Agent notified to restart if needed

---

## Recovery

### Workflow Corrupted State

**Trigger:** Partial write, bug, or external interference

**Impact:** Cannot determine current state

**Mitigation:**
- Event sourcing enables reconstruction
- Replay events to rebuild state
- Admin tool for manual state correction
- Alert on state inconsistency

### Checkpoint Missing

**Trigger:** Crash before checkpoint written

**Impact:** Lost progress since last checkpoint

**Mitigation:**
- Checkpoint after every tool call
- Checkpoint after every user message
- Max lost work: one tool call or message
