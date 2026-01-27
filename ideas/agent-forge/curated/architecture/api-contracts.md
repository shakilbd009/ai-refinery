# API Contracts

## Overview

REST API with JSON payloads. All endpoints require authentication. WebSocket for real-time updates.

**Base URL:** `https://api.agentforge.io`

**Authentication:** `Authorization: Bearer <token>` header required.

---

## Organizations & Members

### Organizations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/organizations` | Any | List user's organizations |
| GET | `/api/organizations/:orgId` | Org member | Get organization details |
| PATCH | `/api/organizations/:orgId` | Admin | Update organization settings |

### Organization Members

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/organizations/:orgId/members` | Org member | List members |
| POST | `/api/organizations/:orgId/members` | Admin | Add member |
| PATCH | `/api/organizations/:orgId/members/:id` | Admin | Update role |
| DELETE | `/api/organizations/:orgId/members/:id` | Admin | Remove member |

---

## Projects

### Project Management

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/organizations/:orgId/projects` | Org member | List projects (filtered by membership) |
| POST | `/api/organizations/:orgId/projects` | Admin/Project Lead | Create project |
| GET | `/api/projects/:projectId` | Project member | Get project details |
| PATCH | `/api/projects/:projectId` | Owner | Update project |
| DELETE | `/api/projects/:projectId` | Owner/Admin | Delete project |

### Project Members

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/projects/:projectId/members` | Viewer+ | List members |
| POST | `/api/projects/:projectId/members` | Owner/Admin | Add member |
| PATCH | `/api/projects/:projectId/members/:id` | Owner/Admin | Update role |
| DELETE | `/api/projects/:projectId/members/:id` | Owner/Admin | Remove member |

---

## Workflow & Conversations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/projects/:projectId/workflow` | Viewer+ | Get workflow state |
| POST | `/api/projects/:projectId/messages` | Editor+ | Send message to agent |
| GET | `/api/projects/:projectId/conversations/:phase` | Viewer+ | Get conversation history |

---

## Artifacts & Approval

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/projects/:projectId/artifacts` | Viewer+ | List artifacts (filter by phase) |
| GET | `/api/projects/:projectId/artifacts/:id` | Viewer+ | Get artifact details |
| POST | `/api/projects/:projectId/artifacts/:id/review` | Approver+ | Approve/reject artifact |
| POST | `/api/projects/:projectId/artifacts/batch-review` | Approver+ | Batch approve/reject |

---

## Escalations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/projects/:projectId/escalations` | Viewer+ | List escalations |
| GET | `/api/projects/:projectId/escalations/:id` | Viewer+ | Get escalation details |
| POST | `/api/projects/:projectId/escalations/:id/resolve` | Approver+ | Resolve escalation |

---

## SME Knowledge

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/organizations/:orgId/sme-knowledge/:agentType` | Org member | List knowledge |
| POST | `/api/organizations/:orgId/sme-knowledge/:agentType/guidelines` | Admin/Curator | Create guideline |
| POST | `/api/organizations/:orgId/sme-knowledge/:agentType/templates` | Admin/Curator | Create template |
| POST | `/api/organizations/:orgId/sme-knowledge/:agentType/examples` | Admin/Curator | Create example |
| POST | `/api/organizations/:orgId/sme-knowledge/:agentType/constraints` | Admin/Curator | Create constraint |
| PATCH | `/api/organizations/:orgId/sme-knowledge/:agentType/:type/:id` | Admin/Curator | Update item |
| DELETE | `/api/organizations/:orgId/sme-knowledge/:agentType/:type/:id` | Admin/Curator | Deactivate item |

---

## Security Review

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/projects/:projectId/security-review` | Viewer+ | Get review summary |
| GET | `/api/projects/:projectId/security-findings` | Viewer+ | List findings |
| POST | `/api/projects/:projectId/security-findings/:id/review` | Approver+ | Accept/provide alternative |

---

## Sandbox Settings

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/organizations/:orgId/sandbox-settings` | Admin | Get sandbox config |
| PATCH | `/api/organizations/:orgId/sandbox-settings` | Admin | Update sandbox config |

---

## WebSocket

**Connection:** `wss://api.agentforge.io/ws?token=<jwt>`

| Event | Payload | Description |
|-------|---------|-------------|
| `agent.progress` | `{ projectId, phase, state, message }` | Agent status |
| `artifact.created` | `{ projectId, artifact }` | New artifact |
| `artifact.updated` | `{ projectId, artifactId, status }` | Status change |
| `escalation.created` | `{ projectId, escalation }` | New escalation |
| `phase.completed` | `{ projectId, phase }` | Phase finished |
| `lock.acquired` | `{ projectId, resourceId, userId }` | Resource locked |
| `lock.released` | `{ projectId, resourceId }` | Resource unlocked |

---

## Related Documents

- [API Examples](./api-examples.md) - Request/response examples
- [Data Model](./data-model.md) - Entity definitions
