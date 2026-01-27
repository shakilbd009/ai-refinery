# ADR-012: Admin Project Override with Logging

## Status
Accepted

## Context
Org Admins need access to projects for support, compliance, and governance. Options:
1. No override - Admins must be added to projects like anyone else
2. Silent override - Admins can access anything
3. Logged override - Admins can access anything, but it's recorded

## Decision
Org Admins **bypass project membership checks** with full logging:

- Admins can access any project in their org
- Admins act as Owner on any project
- All Admin access to non-member projects is logged
- Audit log captures: who, when, what project, what actions

## Consequences

### Positive
- Admins can fulfill governance responsibilities
- Support cases don't require membership changes
- Compliance audits can verify Admin activity
- No blocked Admin scenarios

### Negative
- Potential for Admin overreach
- Users may feel surveilled
- Requires trust in Admin role

### Mitigations
- All Admin access logged for accountability
- Audit logs available to compliance
- Admin role granted sparingly
- Activity feed shows Admin visits to project members
