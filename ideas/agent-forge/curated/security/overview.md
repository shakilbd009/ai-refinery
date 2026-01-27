# Security Overview

## Security Model

AgentForge's security design covers three main areas:

1. **User & Org Permissions** - Multi-tenancy, roles, project access
2. **Agent Sandboxing** - Execution isolation, data boundaries, resource limits
3. **Security Review** - Code vulnerability scanning before completion

---

## Security Principles

- **Org isolation**: Complete data separation between organizations
- **Explicit access**: Projects are private by default
- **Need-to-know**: Agents retrieve specific data, not everything
- **Defense in depth**: Backend enforcement, container isolation, resource limits
- **No exceptions**: Security issues must be fixed; no override path

---

## Permission Model

### Organization Roles

| Role | Scope | Capabilities |
|------|-------|--------------|
| Admin | Org-wide | Full control: members, billing, settings, any project access |
| SME Curator | Org-wide | Manages SME knowledge store |
| Project Lead | Assigned projects | Creates projects, manages membership |
| Member | Assigned projects | Works on assigned projects only |

### Project Roles

| Role | Capabilities |
|------|--------------|
| Owner | Full control, manage membership, delete project |
| Editor | Chat with agents, create/edit artifacts, approve/reject |
| Approver | Review and approve/reject only, read access |
| Viewer | Read-only, observe conversations and artifacts |

---

## Agent Sandboxing

### Execution Models

| Agent | Execution | Rationale |
|-------|-----------|-----------|
| Requirements | API-only | Pure conversation, no code |
| Architecture | API-only | Designs systems, no execution |
| Coding | API + Sandbox | Needs code validation |
| Security | API-only | Reviews code, no execution |

### Container Restrictions

- No network access
- No host filesystem mounts
- Ephemeral storage only (wiped after task)
- No privileged operations
- Read-only base image

---

## Security Review Phase

Fourth phase in the pipeline, mandatory for all projects:

1. Coding phase completes, user approves code
2. Security Agent reviews all code for OWASP vulnerabilities
3. Proposes fixes for any issues found
4. User must accept fix or provide alternative
5. No override path - security issues must be resolved

---

## Related Documents

- [Permissions](./permissions.md) - Detailed permission model
- [Sandboxing](./sandboxing.md) - Container isolation details
- [Review Workflow](./review-workflow.md) - Security Agent process
- [Threat Model](./threat-model.md) - Attack vectors and mitigations
