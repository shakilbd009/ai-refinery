# SME Knowledge Store Implementation Plan

> **Navigation:** This is the overview document. See individual task files for implementation details.

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Go backend foundation with SME Knowledge Store - data models, Firestore storage, and REST API endpoints.

**Architecture:** Go backend with clean architecture (handlers -> service -> repository). Firestore for persistence. RESTful API with JSON. Organization-scoped, agent-type partitioned knowledge.

**Tech Stack:** Go 1.21+, Firestore, Chi router, standard library testing

---

## Task Summary

| Task | File | What It Does |
|------|------|--------------|
| 1-2 | [01-setup-router.md](./01-setup-router.md) | Go project setup with health endpoint, Chi router with structured handlers |
| 3-4 | [02-domain-models.md](./02-domain-models.md) | Domain models with validation, Repository interface definition |
| 5 | [03-repository.md](./03-repository.md) | In-memory repository for development |
| 6 | [04-service.md](./04-service.md) | Service layer with business logic |
| 7-10 | [05-api-handlers.md](./05-api-handlers.md) | Guidelines, Constraints, Templates, Examples API handlers |

---

## API Endpoints Created

```
GET  /health

POST   /api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines/{id}
PUT    /api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines/{id}
DELETE /api/v1/orgs/{orgID}/knowledge/{agentType}/guidelines/{id}

POST   /api/v1/orgs/{orgID}/knowledge/{agentType}/constraints
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/constraints
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/constraints/{id}
DELETE /api/v1/orgs/{orgID}/knowledge/{agentType}/constraints/{id}

POST   /api/v1/orgs/{orgID}/knowledge/{agentType}/templates
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/templates
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/templates/{id}
DELETE /api/v1/orgs/{orgID}/knowledge/{agentType}/templates/{id}

POST   /api/v1/orgs/{orgID}/knowledge/{agentType}/examples
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/examples
GET    /api/v1/orgs/{orgID}/knowledge/{agentType}/examples/{id}
DELETE /api/v1/orgs/{orgID}/knowledge/{agentType}/examples/{id}
```

---

## Future Tasks (Not in This Plan)

- Firestore repository implementation
- Authentication middleware
- Version history tracking
- Workflow snapshot integration
- RAG for examples (embeddings + vector search)
- LLM-judge for constraint validation
