# API Examples

Request/response examples for key API endpoints.

---

## Projects

### Create Project

```http
POST /api/organizations/org-123/projects
Authorization: Bearer <token>

{ "name": "User Auth System", "description": "Build authentication with OAuth and JWT" }
```

```json
{ "id": "proj-1", "name": "User Auth System", "workflowId": "wf-1", "createdAt": "2026-01-15T10:00:00Z" }
```

---

## Workflow

### Get Workflow State

```http
GET /api/projects/proj-1/workflow
```

```json
{
  "id": "wf-1",
  "status": "in_progress",
  "currentPhase": "architecture",
  "phases": [
    { "phase": "requirements", "status": "completed", "completedAt": "2026-01-15T09:00:00Z" },
    { "phase": "architecture", "status": "in_progress", "startedAt": "2026-01-15T09:00:00Z" },
    { "phase": "code", "status": "pending" },
    { "phase": "security_review", "status": "pending" }
  ]
}
```

---

## Conversations

### Send Message

```http
POST /api/projects/proj-1/messages

{ "content": "The system should support OAuth2 login", "phase": "requirements" }
```

```json
{ "messageId": "msg-1", "status": "processing" }
```

### Get Conversation

```http
GET /api/projects/proj-1/conversations/requirements
```

```json
{
  "messages": [
    { "id": "msg-1", "role": "user", "content": "Support OAuth2 login", "timestamp": "2026-01-15T10:00:00Z" },
    { "id": "msg-2", "role": "agent", "content": "What providers?", "artifacts": ["art-1"], "timestamp": "2026-01-15T10:00:05Z" }
  ]
}
```

---

## Artifacts

### List Artifacts

```http
GET /api/projects/proj-1/artifacts?phase=requirements
```

```json
{
  "artifacts": [
    { "id": "art-1", "type": "user_story", "content": { "title": "OAuth Login" }, "status": "pending" }
  ]
}
```

### Approve/Reject

```http
POST /api/projects/proj-1/artifacts/art-1/review

{ "action": "approve" }
```

```json
{ "artifactId": "art-1", "status": "approved" }
```

```http
POST /api/projects/proj-1/artifacts/art-2/review

{ "action": "reject", "feedback": "Missing edge case" }
```

```json
{ "artifactId": "art-2", "status": "needs_revision" }
```

---

## Escalations

### List Escalations

```http
GET /api/projects/proj-1/escalations
```

```json
{
  "escalations": [
    { "id": "esc-1", "artifactId": "art-5", "constraintName": "No hardcoded credentials", "attempts": 3, "status": "pending" }
  ]
}
```

### Resolve with Override

```http
POST /api/projects/proj-1/escalations/esc-1/resolve

{ "action": "override", "reason": "Development-only config file" }
```

```json
{ "escalationId": "esc-1", "status": "resolved", "action": "override" }
```

---

## SME Knowledge

### Create Constraint

```http
POST /api/organizations/org-123/sme-knowledge/coding/constraints

{
  "name": "No console.log",
  "description": "Production code must not use console.log",
  "category": "blocklist",
  "rule": "Code must not contain console.log statements",
  "severity": "error",
  "examples": [{ "violation": "console.log('debug')", "explanation": "Use Logger service" }]
}
```

---

## Security Review

### Get Security Findings

```http
GET /api/projects/proj-1/security-findings
```

```json
{
  "findings": [
    {
      "id": "sf-1",
      "category": "injection",
      "severity": "critical",
      "location": "src/api/users.ts:45",
      "description": "User input passed directly to SQL query",
      "proposedPatch": "db.query('SELECT * FROM users WHERE id = $1', [userId])",
      "status": "pending"
    }
  ]
}
```

### Accept Security Fix

```http
POST /api/projects/proj-1/security-findings/sf-1/review

{ "action": "accept" }
```

```json
{ "findingId": "sf-1", "status": "accepted" }
```
