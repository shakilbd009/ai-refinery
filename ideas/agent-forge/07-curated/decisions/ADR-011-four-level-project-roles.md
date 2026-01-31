# ADR-011: Four-Level Project Roles

## Status
Accepted

## Context
Project access needs granularity beyond read/write. Stakeholders need to approve without driving conversations. Executives need visibility without action capability.

Options:
1. Two roles: Editor, Viewer
2. Three roles: Owner, Editor, Viewer
3. Four roles: Owner, Editor, Approver, Viewer

## Decision
Use **four project roles**:

| Role | Capabilities |
|------|--------------|
| **Owner** | Full control. Manage membership, delete project, all Editor capabilities. |
| **Editor** | Chat with agents, create/edit artifacts, approve/reject, trigger transitions. |
| **Approver** | Review and approve/reject artifacts. Cannot chat or create content. |
| **Viewer** | Read-only. Observe conversations, view artifacts, monitor progress. |

Use cases:
- **Owner**: Project creator, technical lead
- **Editor**: Developers, analysts actively working
- **Approver**: Managers, stakeholders who sign off
- **Viewer**: Executives tracking progress, auditors

## Consequences

### Positive
- Approver role enables stakeholder sign-off without full access
- Viewer role supports monitoring without interference
- Clear capability boundaries
- Supports separation of duties

### Negative
- Four roles more complex than two
- Users must understand role distinctions
- Role assignment requires thought

### Mitigations
- Clear role descriptions in UI
- Default role (Editor) for most additions
- Role capabilities documented in help
