# Permissions Model

## Multi-Tenancy

Organizations are fully isolated tenants. Each org has its own:
- Users and role assignments
- Projects and artifacts
- SME Knowledge store
- Settings and preferences

Data never leaks between orgs. Only shared resource: **Platform Marketplace**.

---

## Organization Roles

| Role | Capabilities |
|------|--------------|
| **Admin** | Full control: members, billing, settings. Can force SME knowledge on all projects. Can access any project. |
| **SME Curator** | Manages org's SME knowledge store. Enables/disables marketplace items. Cannot manage members or billing. |
| **Project Lead** | Creates projects, manages project membership. Full control within their projects. |
| **Member** | Works on projects they're added to. No org-wide permissions. |

Role hierarchy: Admins inherit all capabilities. SME Curator and Project Lead are peer roles.

---

## Project Permissions

### Access Model

Projects are **private by default**. Users must be explicitly added. Org Admins can access any project regardless of membership.

### Project Roles

| Role | Capabilities |
|------|--------------|
| **Owner** | Full control. Manage membership, delete project. At least one required. |
| **Editor** | Chat with agents, create/edit artifacts, approve/reject, trigger transitions. |
| **Approver** | Review and approve/reject. Cannot chat or create content. |
| **Viewer** | Read-only. Observe conversations, view artifacts, monitor progress. |

### Membership Rules

- Project creator automatically becomes Owner
- Owners can add/remove any role except other Owners
- Only Admins can remove the last Owner or delete a project

---

## SME Knowledge Permissions

| Scope | Managed By | Visibility |
|-------|------------|------------|
| Platform Marketplace | Platform operator | All orgs can browse and enable |
| Org Knowledge | SME Curators | Only within that org |

### Org-Level Enforcement

Admins can mark knowledge items as **mandatory** - they apply to all projects. Project Leads cannot disable mandatory items.

---

## Authorization Flow

```
1. Is user authenticated? → No → Reject
2. Is resource in user's org? → No → Reject
3. Does user have required role? → No → Reject
4. Action permitted
```

### Admin Override

Org Admins bypass project membership checks. They can:
- Access any project in their org
- Act as Owner on any project
- All access logged for audit

---

## Related ADRs

- [ADR-010: Private-by-Default Projects](../decisions/ADR-010-private-by-default.md)
- [ADR-011: Four-Level Project Roles](../decisions/ADR-011-four-level-project-roles.md)
- [ADR-012: Admin Project Override with Logging](../decisions/ADR-012-admin-override-logging.md)
