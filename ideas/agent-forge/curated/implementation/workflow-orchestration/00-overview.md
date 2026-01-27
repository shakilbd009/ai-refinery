# Workflow Orchestration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the workflow engine that orchestrates agent collaboration, phase transitions, human approvals, and escalation handling.

**Architecture:** Extends existing Go backend with workflow domain models, repository layer, service layer, and REST API. Uses event sourcing for audit trail. Follows established patterns from SME Knowledge Store.

**Tech Stack:** Go 1.21+, Chi router, in-memory repository (Firestore-ready), standard library testing

---

## Implementation Tasks

This plan is split into focused files for efficient parallel agent processing:

| File | Tasks | Description |
|------|-------|-------------|
| [01-domain-models.md](./01-domain-models.md) | 1-5 | Workflow domain models, enums, escalation, events |
| [02-repository.md](./02-repository.md) | 6-9 | Repository interface and in-memory implementation |
| [03-service.md](./03-service.md) | 10-13 | Workflow service methods |
| [04-api-handlers.md](./04-api-handlers.md) | 14-17 | API handlers and routes |

---

## Task Summary

### Domain Models (Tasks 1-5)
1. **Task 1:** Workflow Domain Models - Phase and WorkflowStatus enums
2. **Task 2:** PhaseStatus and TaskStatus Enums
3. **Task 3:** Workflow Struct with Validation
4. **Task 4:** Escalation Domain Model
5. **Task 5:** Event Domain Model for Event Sourcing

### Repository Layer (Tasks 6-9)
6. **Task 6:** Workflow Repository Interface
7. **Task 7:** In-Memory Workflow Repository - Core Operations
8. **Task 8:** In-Memory Workflow Repository - Escalation Operations
9. **Task 9:** In-Memory Workflow Repository - Event Operations

### Service Layer (Tasks 10-13)
10. **Task 10:** Workflow Service - Create Workflow
11. **Task 11:** Workflow Service - Start Workflow
12. **Task 12:** Workflow Service - Complete Phase and Transition
13. **Task 13:** Workflow Service - Escalation Handling

### API Layer (Tasks 14-17)
14. **Task 14:** Workflow API Handler
15. **Task 15:** Wire Up Workflow Routes
16. **Task 16:** Add Complete Phase and Escalation Endpoints
17. **Task 17:** Run All Tests

---

## Summary

This plan implements the core Workflow Orchestration system:

1. **Domain Models** (Tasks 1-5): Phase, WorkflowStatus, PhaseStatus, TaskStatus enums; Workflow, PhaseState, Task, Escalation, Event structs with validation

2. **Repository Layer** (Tasks 6-9): WorkflowRepository interface with in-memory implementation for workflows, escalations, and events

3. **Service Layer** (Tasks 10-13): WorkflowService with CreateWorkflow, StartWorkflow, CompletePhase, escalation handling

4. **API Layer** (Tasks 14-16): HTTP handlers and routes for workflow CRUD, phase transitions, and escalations

**Not Included (Future Tasks):**
- Multi-user locking
- Change requests and re-work
- Notification system
- Checkpointing for recovery
- Frontend integration
