# Security Permissions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement multi-tenant security model with organization roles, project permissions, and SME knowledge access control.

**Architecture:** Four-layer architecture following existing codebase patterns: domain models → repository interfaces/implementations → services → HTTP handlers. Permission checking via middleware with admin override capability.

**Tech Stack:** Go 1.25, Chi router, Firestore struct tags (memory repository for now)

---

## Plan Structure

This implementation is split into multiple focused plans:

| Part | File | Description |
|------|------|-------------|
| 1 | [01-data-models.md](./01-data-models.md) | Domain models: Organization, OrgMembership, ProjectMembership, role enums |
| 2 | [02-org-permissions.md](./02-org-permissions.md) | Organization management: CRUD, member management |
| 3 | [03-project-permissions.md](./03-project-permissions.md) | Project membership: roles, access control |
| 4 | [04-authorization-middleware.md](./04-authorization-middleware.md) | Permission checking, admin override, cross-org prevention |
| 5 | [05-sme-knowledge-permissions.md](./05-sme-knowledge-permissions.md) | Knowledge access control, marketplace enablement |

---

## Implementation Order

Execute plans in order (1 → 5). Each plan builds on the previous:

```
01-data-models (foundation)
    ↓
02-org-permissions (org layer)
    ↓
03-project-permissions (project layer)
    ↓
04-authorization-middleware (enforcement)
    ↓
05-sme-knowledge-permissions (knowledge layer)
```

---

## Design Reference

Source design document: `docs/plans/security-permissions-design.md`

### Key Design Decisions

- **Org isolation**: Complete data separation between organizations
- **Private by default**: Projects require explicit membership
- **Four org roles**: Admin, SME Curator, Project Lead, Member
- **Four project roles**: Owner, Editor, Approver, Viewer
- **Admin override**: Admins can access any project (logged for audit)
- **Cross-org prevention**: Hard enforcement at data layer

---

## Files to Create (Summary)

```
internal/
├── domain/
│   └── permissions.go           # Part 1
├── repository/
│   ├── permissions_repository.go # Part 2-3
│   └── memory/
│       └── permissions_repository.go # Part 2-3
├── service/
│   ├── org_service.go           # Part 2
│   └── project_permissions_service.go # Part 3
├── api/
│   ├── middleware/
│   │   └── permissions.go       # Part 4
│   └── handlers/
│       ├── organizations.go     # Part 2
│       └── project_members.go   # Part 3
└── routes/
    └── routes.go                # Updated in Parts 2-4
```

---

## Testing Strategy

- TDD approach: Write failing test → implement → verify pass
- Repository tests: CRUD operations, org isolation
- Service tests: Business logic, role validation
- Handler tests: HTTP request/response, error cases
- Middleware tests: Permission checks, admin bypass

---

## Estimated Task Count

- Part 1: 8 tasks (data models)
- Part 2: 15 tasks (org permissions)
- Part 3: 12 tasks (project permissions)
- Part 4: 10 tasks (middleware)
- Part 5: 8 tasks (knowledge permissions)

**Total: ~53 tasks**
