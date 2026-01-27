# ADR-010: Private-by-Default Projects

## Status
Accepted

## Context
Project visibility options:
1. Public within org - all org members see all projects
2. Private by default - explicit membership required
3. Team-based - projects belong to teams

## Decision
Projects are **private by default**. Users must be explicitly added to access a project.

- Project creator automatically becomes Owner
- Additional members added explicitly with specific roles
- Org Admins can access any project (logged for audit)
- No "org-wide" project visibility setting

## Consequences

### Positive
- Confidentiality for sensitive projects
- Clear ownership and access control
- Users only see what's relevant to them
- Supports compliance requirements (need-to-know)

### Negative
- More administrative overhead to add members
- New team members don't automatically see existing projects
- Risk of siloed information

### Mitigations
- Project Leads can manage membership for their projects
- Admins can access any project when needed
- Project list shows all projects user has access to
- Org Admins can audit project membership
