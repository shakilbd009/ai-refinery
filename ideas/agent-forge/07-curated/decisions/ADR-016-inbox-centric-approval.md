# ADR-016: Inbox-Centric Approval Model

## Status
Accepted

## Context
Users need to know what requires their attention across all projects. Options:
1. Per-project notifications - check each project individually
2. Email-only - all notifications via email
3. Inbox model - central place for all action items

## Decision
Use an **inbox-centric approval model**:

Dedicated Inbox page aggregates all attention items across projects:

| Category | Description |
|----------|-------------|
| Pending Approvals | Phase reviews waiting for sign-off |
| Revision Ready | Reworked items ready for re-review |
| Escalations | Constraint violations agent couldn't resolve |
| Questions | Agent needs clarification |

Each item shows: Project name, phase, description, age, one-click action.

Global navigation includes Inbox with badge count showing pending items.

## Consequences

### Positive
- Single place to see all pending work
- No need to check each project individually
- Badge count shows at-a-glance workload
- One-click actions reduce friction

### Negative
- Must maintain Inbox state across projects
- Could become overwhelming with many projects
- Users may ignore Inbox and work per-project

### Mitigations
- Inbox items grouped by project/type
- Filtering and sorting options
- Empty state encourages with "You're all caught up!"
- Notifications can also go to email/Slack
